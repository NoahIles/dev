//! Pure text handling for the Stop hook: which part of a reply gets spoken.
//!
//! This is a port of a grep/sed/tr pipeline and is meant to match it exactly,
//! quirks included. Terms (gist, truncation) are defined in the repo's
//! CONTEXT.md.

use serde_json::Value;

const MARK: char = '🔊';

/// POSIX `[[:space:]]` without the newline, which never occurs inside a line.
fn is_space(c: char) -> bool {
    matches!(c, ' ' | '\t' | '\r' | '\x0b' | '\x0c')
}

/// What follows the mark on a gist line, or `None` if this is not one.
fn after_mark(line: &str) -> Option<&str> {
    line.trim_start_matches(is_space).strip_prefix(MARK)
}

/// The sentence on the first gist line. Only the first line is considered: an
/// empty gist there does not fall through to a later one.
pub fn gist(raw: &str) -> Option<&str> {
    let rest = raw.split('\n').find_map(after_mark)?;
    Some(rest.trim_start_matches(is_space))
}

/// The reply as one line for the ear: fenced code and gist lines dropped,
/// markdown punctuation stripped, URLs spoken as "link".
pub fn clean(raw: &str) -> String {
    let mut joined = String::with_capacity(raw.len());
    let mut in_fence = false;
    let mut lines = raw.split('\n').peekable();
    while let Some(line) = lines.next() {
        let fence = line.starts_with("```");
        let dropped = in_fence || fence || after_mark(line).is_some();
        if fence {
            in_fence = !in_fence;
        }
        if dropped {
            continue;
        }
        joined.push_str(&clean_line(line));
        // sed ends every kept line but the input's last with a newline, which
        // tr then turns into a space. A dropped line leaves nothing behind.
        if lines.peek().is_some() {
            joined.push(' ');
        }
    }
    squeeze_spaces(&joined)
}

fn clean_line(line: &str) -> String {
    let plain: String = line.chars().filter(|c| !"`*_#>|".contains(*c)).collect();
    let linked = replace_urls(&plain);
    // A leading list dash becomes a single space.
    match linked.trim_start_matches(is_space).strip_prefix('-') {
        Some(item) => format!(" {}", item.trim_start_matches(is_space)),
        None => linked,
    }
}

/// sed's `s|https\?://[^ ]*|link|g`: a URL runs to the next space.
fn replace_urls(line: &str) -> String {
    let mut out = String::with_capacity(line.len());
    let mut rest = line;
    while let Some(start) = [rest.find("http://"), rest.find("https://")].into_iter().flatten().min() {
        let Some((before, url)) = rest.split_at_checked(start) else { break };
        out.push_str(before);
        out.push_str("link");
        rest = url.find(' ').and_then(|end| url.get(end..)).unwrap_or("");
    }
    out.push_str(rest);
    out
}

/// `tr -s ' '`: runs of spaces collapse to one. Other whitespace is untouched.
fn squeeze_spaces(text: &str) -> String {
    let mut out = String::with_capacity(text.len());
    for c in text.chars() {
        if c != ' ' || !out.ends_with(' ') {
            out.push(c);
        }
    }
    out
}

/// Truncation: the first `max_bytes` of `clean`, cut back to a sentence
/// boundary. The fallback for gist mode when no gist line was emitted.
pub fn truncate(clean: &str, max_bytes: usize) -> &str {
    // The bash cut raw bytes (`head -c`) and could split a character; this
    // cuts at the last whole character at or before the limit instead.
    let short = clean.get(..clean.floor_char_boundary(max_bytes)).unwrap_or(clean);
    let trimmed = short.trim_end_matches(|c| !matches!(c, '.' | '!' | '?'));
    if trimmed.is_empty() { short } else { trimmed }
}

fn entries<'a>(lines: impl Iterator<Item = &'a str>) -> impl Iterator<Item = Value> {
    lines.filter_map(|line| serde_json::from_str(line).ok())
}

fn is_assistant(entry: &Value) -> bool {
    entry.get("type").and_then(Value::as_str) == Some("assistant")
}

/// Transcript fallback: has the turn's final text block been flushed yet?
/// True when the last assistant entry in the last 20 lines opens with text.
pub fn transcript_tail_is_text(transcript: &str) -> bool {
    let lines: Vec<&str> = transcript.lines().collect();
    let tail = lines.iter().skip(lines.len().saturating_sub(20)).copied();
    let kind = entries(tail)
        .filter(is_assistant)
        .last()
        .and_then(|entry| Some(entry.pointer("/message/content/0/type")?.as_str()?.to_owned()));
    kind.as_deref() == Some("text")
}

/// Transcript fallback: the last text block of any assistant entry.
pub fn transcript_last_text(transcript: &str) -> Option<String> {
    entries(transcript.lines())
        .filter(is_assistant)
        .filter_map(|entry| {
            let blocks = entry.pointer("/message/content")?.as_array()?;
            let texts = blocks.iter().filter(|b| b.get("type").and_then(Value::as_str) == Some("text"));
            texts.filter_map(|b| Some(b.get("text")?.as_str()?.to_owned())).next_back()
        })
        .last()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn gist_is_the_first_marked_line() {
        assert_eq!(gist("Long answer.\n\n🔊 All done, nothing to do.\n🔊 second"), Some("All done, nothing to do."));
        assert_eq!(gist("  \t🔊   indented"), Some("indented"));
        assert_eq!(gist("no mark here\nmid-line 🔊 does not count"), None);
        // An empty first gist wins over a later one; the caller treats it as none.
        assert_eq!(gist("🔊 \n🔊 later"), Some(""));
    }

    #[test]
    fn clean_drops_fenced_code() {
        assert_eq!(clean("Run this:\n```bash\nrm -rf /\n```\nThen stop."), "Run this: Then stop.");
        // An unclosed fence swallows the rest; an indented one is not a fence.
        assert_eq!(clean("a\n```\nb\nc"), "a ");
        assert_eq!(clean("a\n  ```\nb"), "a b");
    }

    #[test]
    fn clean_strips_markdown_urls_and_list_dashes() {
        assert_eq!(clean("## A **bold** `move`"), " A bold move");
        assert_eq!(clean("see https://example.com/a_b#c and http://x.y, ok"), "see link and link ok");
        assert_eq!(clean("- one\n  -   two\na - b"), " one two a - b");
        assert_eq!(clean("| a | b |\n> quote"), " a b quote");
    }

    #[test]
    fn clean_drops_gist_lines_and_keeps_seds_trailing_space() {
        assert_eq!(clean("Answer.\n\n🔊 spoken"), "Answer. ");
        assert_eq!(clean("a\n\n\nb   c"), "a b c");
        assert_eq!(clean(""), "");
    }

    #[test]
    fn truncate_cuts_back_to_the_last_sentence_end() {
        assert_eq!(truncate("One. Two! Three? Four and", 300), "One. Two! Three?");
        assert_eq!(truncate("First sentence. Second sentence.", 20), "First sentence.");
        // Even text under the limit loses its unfinished tail.
        assert_eq!(truncate("Done. And then", 300), "Done.");
    }

    #[test]
    fn truncate_without_a_sentence_end_keeps_the_cut_text() {
        assert_eq!(truncate("no punctuation at all", 300), "no punctuation at all");
        assert_eq!(truncate("no punctuation at all", 6), "no pun");
        assert_eq!(truncate("", 300), "");
    }

    #[test]
    fn truncate_never_splits_a_character() {
        // 'é' is two bytes, so byte 2 falls inside it: cut before it instead.
        assert_eq!(truncate("héllo", 2), "h");
        assert_eq!(truncate("Ok. 🔊🔊", 6), "Ok.");
    }

    const TRANSCRIPT: &str = concat!(
        r#"{"type":"user","message":{"content":"hi"}}"#,
        "\n",
        r#"{"type":"assistant","message":{"content":[{"type":"text","text":"first"}]}}"#,
        "\n",
        r#"{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash"}]}}"#,
        "\n",
        "{ half-written line",
    );

    #[test]
    fn transcript_fallback_reads_the_last_text_block() {
        assert_eq!(transcript_last_text(TRANSCRIPT).as_deref(), Some("first"));
        assert!(!transcript_tail_is_text(TRANSCRIPT));
        let flushed = format!(
            "{TRANSCRIPT}\n{}",
            r#"{"type":"assistant","message":{"content":[{"type":"text","text":"a"},{"type":"text","text":"final"}]}}"#
        );
        assert_eq!(transcript_last_text(&flushed).as_deref(), Some("final"));
        assert!(transcript_tail_is_text(&flushed));
        assert_eq!(transcript_last_text(""), None);
    }
}
