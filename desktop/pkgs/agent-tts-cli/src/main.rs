//! Claude Code's TTS hooks and helpers, as one binary that dispatches on the
//! name it was called as (the Nix package symlinks each name to it).
//!
//! Hooks must never block Claude: failures exit 1 at worst, never 2.

mod conf;
mod text;

use std::error::Error;
use std::fs::{self, File};
use std::io::{self, Read};
use std::path::Path;
use std::process::{Command, ExitCode, Stdio};
use std::thread::sleep;
use std::time::Duration;
use std::env;

use conf::Conf;
use serde_json::Value;

const fn or(value: Option<&'static str>, default: &'static str) -> &'static str {
    match value {
        Some(value) => value,
        None => default,
    }
}

// The Nix build pins all of these; the defaults keep a plain `cargo build`
// working, with the tools looked up on PATH.
const PORT: &str = or(option_env!("AGENT_TTS_PORT"), "8765");
const BREEZE_PORT: &str = or(option_env!("AGENT_TTS_BREEZE_PORT"), "8766");
// ponytail: playback is a transient systemd unit rather than a tracked PID.
// systemd owns the singleton, so "stop the current clip" is one command with
// no stale-PID race, and a new clip supersedes the old one by unit name.
const PLAY_UNIT: &str = or(option_env!("AGENT_TTS_PLAY_UNIT"), "claude-tts-play");
const SYSTEMCTL: &str = or(option_env!("AGENT_TTS_SYSTEMCTL"), "systemctl");
const SYSTEMD_RUN: &str = or(option_env!("AGENT_TTS_SYSTEMD_RUN"), "systemd-run");
const PW_PLAY: &str = or(option_env!("AGENT_TTS_PW_PLAY"), "pw-play");
const XDG_OPEN: &str = or(option_env!("AGENT_TTS_XDG_OPEN"), "xdg-open");

const DEFAULT_GIST_PROMPT: &str = "End every reply with a line starting '🔊 ' holding one short spoken-English sentence saying what you did and whether I need to act.";

type Result<T> = std::result::Result<T, Box<dyn Error>>;

fn main() -> ExitCode {
    let mut args = env::args();
    let argv0 = args.next().unwrap_or_default();
    let mut name = Path::new(&argv0).file_name().and_then(|n| n.to_str()).unwrap_or_default().to_owned();
    if name == "agent-tts" {
        name = args.next().unwrap_or_default();
    }
    let result = match name.as_str() {
        "claude-speak" => speak(),
        "claude-tts-prompt" => {
            prompt();
            Ok(())
        }
        "claude-shut-up" => {
            stop_playback();
            Ok(())
        }
        "claude-tts-config" => config(),
        "claude-tts-voices" => voices(args),
        other => Err(format!("unknown command {other:?}").into()),
    };
    match result {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("{name}: {error}");
            ExitCode::FAILURE
        }
    }
}

fn kokoro(path: &str) -> String {
    format!("http://127.0.0.1:{PORT}{path}")
}

/// Failures are ignored on purpose: no unit to stop is the normal case.
fn systemctl(args: &[&str]) {
    let _ = Command::new(SYSTEMCTL).arg("--user").args(args).stderr(Stdio::null()).status();
}

fn stop_playback() {
    systemctl(&["stop", &format!("{PLAY_UNIT}.service")]);
}

fn warm_breeze() {
    systemctl(&["start", "--no-block", "breeze-tts.service"]);
}

fn agent(total: Option<Duration>, connect: Option<Duration>) -> ureq::Agent {
    ureq::Agent::config_builder().timeout_global(total).timeout_connect(connect).build().into()
}

/// POST `text` for synthesis and stream the WAV that comes back into `sink`.
fn synthesize(
    agent: &ureq::Agent,
    url: &str,
    headers: &[(&str, &str)],
    text: &str,
    sink: &mut impl io::Write,
) -> Result<()> {
    let mut request = agent.post(url);
    for (name, value) in headers {
        request = request.header(*name, *value);
    }
    let mut response = request.send(text)?;
    io::copy(&mut response.body_mut().as_reader(), sink)?;
    Ok(())
}

/// Stop hook: speak the reply Claude Code pipes in on stdin.
fn speak() -> Result<()> {
    let conf = Conf::load();
    let mode = conf.get("MODE", "gist");
    if mode == "off" {
        return Ok(());
    }

    let mut input = String::new();
    io::stdin().read_to_string(&mut input)?;
    if input.trim().is_empty() {
        return Ok(());
    }
    let payload: Value = serde_json::from_str(&input)?;
    let field = |key| payload.get(key).and_then(Value::as_str).filter(|value: &&str| !value.is_empty());

    // Claude Code hands the Stop hook the final text directly. Reading the
    // transcript instead raced its flush and spoke the *previous* turn.
    let raw = match field("last_assistant_message") {
        Some(message) => message.to_owned(),
        // ponytail: fallback for Claude Code versions without the field.
        None => match field("transcript_path").and_then(|path| from_transcript(Path::new(path))) {
            Some(message) => message,
            None => return Ok(()),
        },
    };
    let raw = raw.trim_end_matches('\n');

    // In gist mode Claude marks one spoken sentence with a leading 🔊.
    let gist = if mode == "gist" { text::gist(raw).filter(|gist| !gist.is_empty()) } else { None };
    // Fenced code never reaches the ear — that is the read/hear boundary the
    // conversational output style leans on. Markdown and URLs go too.
    let clean = text::clean(raw);
    let spoken = match gist {
        Some(gist) => gist,
        // Written for the ear already; speaking half of it is the bug we fixed.
        None if mode == "conversational" => &clean,
        // ponytail: an unparsable FALLBACK_CHARS means the default, not an error.
        None => text::truncate(&clean, conf.get("FALLBACK_CHARS", "300").parse().unwrap_or(300)),
    };
    if spoken.chars().all(|c| c == ' ') {
        return Ok(());
    }

    // One fixed path, not a temp file: playback outlives this hook, so the
    // file must too, and only one clip ever plays at a time.
    let runtime_dir = env::var("XDG_RUNTIME_DIR").ok().filter(|dir| !dir.is_empty());
    let wav = format!("{}/claude-tts.wav", runtime_dir.as_deref().unwrap_or("/tmp"));
    stop_playback();

    let timeout = Duration::try_from_secs_f64(conf.get("TIMEOUT", "120").parse().unwrap_or(120.0))
        .unwrap_or(Duration::from_mins(2));
    let mut ok = false;
    if conf.get("ENGINE", "kokoro") == "breeze" {
        // Breeze only listens once warm. Refused means it is still loading (or
        // stopped), so start it and let Kokoro take this reply.
        let breeze = agent(Some(timeout), Some(Duration::from_secs(1)));
        let url = format!("http://127.0.0.1:{BREEZE_PORT}");
        ok = synthesize(&breeze, &url, &[], spoken, &mut File::create(&wav)?).is_ok();
        if !ok {
            warm_breeze();
        }
    }
    if !ok {
        let headers = [("X-Voice", &*conf.get("VOICE", "af_heart")), ("X-Speed", &*conf.get("SPEED", "1.1"))];
        ok = synthesize(&agent(Some(timeout), None), &kokoro(""), &headers, spoken, &mut File::create(&wav)?).is_ok();
    }
    if ok && fs::metadata(&wav).is_ok_and(|meta| meta.len() > 0) {
        let _ = Command::new(SYSTEMD_RUN)
            .args(["--user", "--quiet", "--collect", &format!("--unit={PLAY_UNIT}"), "--property=Type=exec", "--", PW_PLAY, &wav])
            .status();
    }
    Ok(())
}

/// Wait up to two seconds for the turn's text to be flushed, then read it.
fn from_transcript(path: &Path) -> Option<String> {
    if !path.is_file() {
        return None;
    }
    for _ in 0..10 {
        if text::transcript_tail_is_text(&fs::read_to_string(path).ok()?) {
            break;
        }
        sleep(Duration::from_millis(200));
    }
    text::transcript_last_text(&fs::read_to_string(path).ok()?)
}

/// `UserPromptSubmit` hook: two jobs, both cheap. Stop talking the moment
/// Noah submits, and inject the gist instruction while gist mode is on.
fn prompt() {
    let conf = Conf::load();
    let mode = conf.get("MODE", "gist");
    stop_playback();
    // Start warming Breeze while Claude works, so the reply can use it.
    if conf.get("ENGINE", "kokoro") == "breeze" && mode != "off" {
        warm_breeze();
    }
    if mode == "gist" {
        println!("{}", conf.get("GIST_PROMPT", DEFAULT_GIST_PROMPT));
    }
}

fn config() -> Result<()> {
    // A GET wakes the socket-activated daemon before the browser asks for the page.
    let _ = agent(Some(Duration::from_secs(30)), None).get(kokoro("/config")).call();
    if Command::new(XDG_OPEN).arg(kokoro("/")).status()?.success() {
        Ok(())
    } else {
        Err("xdg-open failed".into())
    }
}

/// No arguments: list the Kokoro voices. Otherwise audition each one named.
fn voices(names: impl Iterator<Item = String>) -> Result<()> {
    let mut names = names.peekable();
    if names.peek().is_none() {
        let list: Value = serde_json::from_reader(agent(None, None).get(kokoro("/voices")).call()?.body_mut().as_reader())?;
        for voice in list.as_array().into_iter().flatten() {
            println!("{}", voice.as_str().map_or_else(|| voice.to_string(), str::to_owned));
        }
        return Ok(());
    }
    // Not the config layer: this one only ever read SPEED from the environment.
    let speed = Conf::default().get("SPEED", "1.1");
    let agent = agent(Some(Duration::from_mins(2)), None);
    for voice in names {
        println!("--- {voice}");
        // "af_heart" introduces itself as "heart".
        let mut chars = voice.chars();
        let prefixed = chars.nth(2) == Some('_');
        let name = if prefixed { chars.as_str() } else { &voice };
        let line = format!("Hi Noah, this is {name}. Here is how I sound reading one of Claude's replies.");
        let Ok(mut player) = Command::new(PW_PLAY).arg("-").stdin(Stdio::piped()).stderr(Stdio::null()).spawn() else {
            continue;
        };
        if let Some(mut stdin) = player.stdin.take() {
            let _ = synthesize(&agent, &kokoro(""), &[("X-Voice", &voice), ("X-Speed", &speed)], &line, &mut stdin);
        }
        let _ = player.wait();
    }
    Ok(())
}
