{
  lib,
  rustPlatform,
  clippy,
  systemd,
  pipewire,
  xdg-utils,
  port,
  breezePort,
  playUnit,
}:
rustPlatform.buildRustPackage {
  pname = "agent-tts";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [./Cargo.toml ./Cargo.lock ./clippy.toml ./src];
  };
  cargoLock.lockFile = ./Cargo.lock;

  # Compiled in (see the option_env! block in main.rs), so the binary needs no
  # wrapper and the ports have one source of truth: agent-tts.nix.
  env = {
    AGENT_TTS_PORT = toString port;
    AGENT_TTS_BREEZE_PORT = toString breezePort;
    AGENT_TTS_PLAY_UNIT = playUnit;
    AGENT_TTS_SYSTEMCTL = "${systemd}/bin/systemctl";
    AGENT_TTS_SYSTEMD_RUN = "${systemd}/bin/systemd-run";
    AGENT_TTS_PW_PLAY = "${pipewire}/bin/pw-play";
    AGENT_TTS_XDG_OPEN = "${xdg-utils}/bin/xdg-open";
  };

  # The [lints] table in Cargo.toml only bites under clippy, so run it here:
  # a lint violation fails the build like a failing test does.
  nativeCheckInputs = [clippy];
  postCheck = "cargo clippy --offline --all-targets -- -D warnings";

  # One binary, dispatching on the name it was called as.
  postInstall = ''
    for name in claude-speak claude-tts-prompt claude-shut-up claude-tts-config claude-tts-voices; do
      ln -s agent-tts $out/bin/$name
    done
  '';
}
