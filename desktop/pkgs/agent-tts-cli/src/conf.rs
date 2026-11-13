//! The mutable config layer: `~/.claude/tts.conf`, written by the daemon's UI
//! as `KEY=value` lines with shell quoting (Python's `shlex.quote`).

use std::collections::HashMap;
use std::{env, fs};

#[derive(Default)]
pub struct Conf(HashMap<String, String>);

impl Conf {
    /// A missing or unreadable file is an empty config, not an error.
    pub fn load() -> Self {
        let home = env::var("HOME").unwrap_or_default();
        fs::read_to_string(format!("{home}/.claude/tts.conf"))
            .map(|body| Self::parse(&body))
            .unwrap_or_default()
    }

    // ponytail: literals only. The bash hooks `source`d this file, so shell
    // syntax in a hand edit ($VAR, $(cmd)) used to run; here it is plain text.
    pub fn parse(body: &str) -> Self {
        let pairs = body.lines().filter_map(|line| {
            let line = line.trim();
            if line.starts_with('#') {
                return None;
            }
            let (key, value) = line.split_once('=')?;
            // Unbalanced quotes: skip the line rather than guess.
            let value = shlex::split(value)?.into_iter().next().unwrap_or_default();
            Some((key.trim().to_owned(), value))
        });
        Self(pairs.collect())
    }

    /// Bash's `${KEY:-default}` after sourcing the file: the file wins, then
    /// the environment, and an empty value counts as unset.
    pub fn get(&self, key: &str, default: &str) -> String {
        self.0
            .get(key)
            .cloned()
            .or_else(|| env::var(key).ok())
            .filter(|value| !value.is_empty())
            .unwrap_or_else(|| default.to_owned())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reads_what_the_ui_writes() {
        // shlex.quote output: bare words, single quotes, and '"'"' for a quote.
        let conf = Conf::parse(
            "# Claude Code TTS config.\nMODE=gist\nSPEED=1.1\n\
             GIST_PROMPT='a line starting \"🔊 \" and it'\"'\"'s short'\n",
        );
        assert_eq!(conf.get("MODE", "x"), "gist");
        assert_eq!(conf.get("SPEED", "x"), "1.1");
        assert_eq!(conf.get("GIST_PROMPT", "x"), "a line starting \"🔊 \" and it's short");
    }

    #[test]
    fn empty_and_missing_fall_back_to_the_default() {
        let conf = Conf::parse("MODE=\nVOICE=''\n");
        assert_eq!(conf.get("MODE", "gist"), "gist");
        assert_eq!(conf.get("VOICE", "af_heart"), "af_heart");
        assert_eq!(conf.get("AGENT_TTS_TEST_UNSET_KEY", "kokoro"), "kokoro");
    }

    #[test]
    fn trailing_comments_and_bad_lines_are_ignored() {
        let conf = Conf::parse("MODE=off # quiet\nnot a pair\nVOICE='unclosed\nENGINE=breeze\n");
        assert_eq!(conf.get("MODE", "x"), "off");
        assert_eq!(conf.get("VOICE", "af_heart"), "af_heart");
        assert_eq!(conf.get("ENGINE", "x"), "breeze");
    }
}
