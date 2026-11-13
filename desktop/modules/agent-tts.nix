{
  pkgs,
  identity,
  ...
}: let
  # ponytail: the CUDA python env is deliberately NOT in this closure. nixpkgs'
  # torch would drag in cudaPackages.nccl, which Hydra never builds (unfree), so
  # every CUDA bump would mean a ~30min local NCCL kernel compile and +4-6GB of
  # closure. Instead the env is a uv venv of upstream PyTorch wheels, created
  # once by `claude-tts-setup` (works because programs.nix-ld.enable is on).
  # Everything else — units, daemon, scripts, UI — is declared here.
  venv = "${identity.homeDirectory}/.claude/hooks/tts-venv";
  port = 8765;

  # The whole directory, not just daemon.py: the daemon reads ui.html beside itself.
  daemonSrc = ./../pkgs/agent-tts;

  # Breeze TTS 2: the cloned-voice engine. Same trade as Kokoro: the code is
  # pinned here, the CUDA venv and the ~7 GB of weights live outside the closure
  # and come from `claude-tts-setup-breeze`. The voice itself is two mutable
  # files: ~/.claude/tts-voice/ref.wav and its exact transcript, ref.txt.
  breezeVenv = "${identity.homeDirectory}/.claude/hooks/breeze-venv";
  breezeModel = "${identity.homeDirectory}/.local/share/breeze-tts/Breeze-TTS-2";
  breezePort = 8766;
  breezeSrc = pkgs.fetchFromGitHub {
    owner = "breezeblue-ai";
    repo = "breeze-tts";
    rev = "6eba901d1845353802652c708a4740fdfc5baa75";
    hash = "sha256-5ZLpIWxpVOj7q6ov6S9j1GVDwy2WYQFa76MJxhn9WKk=";
  };

  # The hooks and helpers (claude-speak, claude-tts-prompt, claude-shut-up,
  # claude-tts-config, claude-tts-voices): one Rust binary under five names.
  cli = pkgs.callPackage ../pkgs/agent-tts-cli {
    inherit port breezePort;
    playUnit = "claude-tts-play";
  };

  # One command to (re)create the venv on a fresh machine.
  setup = pkgs.writeShellApplication {
    name = "claude-tts-setup";
    runtimeInputs = [pkgs.uv pkgs.coreutils];
    text = ''
      export UV_LINK_MODE=copy
      rm -rf "${venv}"
      mkdir -p "$(dirname "${venv}")"
      uv venv --python 3.12 "${venv}"
      uv pip install --python "${venv}/bin/python" \
        --index-strategy unsafe-best-match \
        --extra-index-url https://download.pytorch.org/whl/cu128 \
        torch kokoro soundfile numpy spacy \
        https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl
      echo "venv ready; restart with: systemctl --user restart kokoro-tts.service"
    '';
  };

  # The Breeze venv (upstream's pinned requirements) and its weights.
  setupBreeze = pkgs.writeShellApplication {
    name = "claude-tts-setup-breeze";
    runtimeInputs = [pkgs.uv pkgs.coreutils];
    text = ''
      export UV_LINK_MODE=copy
      rm -rf "${breezeVenv}"
      mkdir -p "$(dirname "${breezeVenv}")" "${breezeModel}"
      uv venv --python 3.12 "${breezeVenv}"
      uv pip install --python "${breezeVenv}/bin/python" \
        -r ${breezeSrc}/requirements.txt "huggingface_hub[cli]"
      "${breezeVenv}/bin/hf" download BreezeBlue/Breeze-TTS-2 --local-dir "${breezeModel}"
      echo "ready; put the voice in ~/.claude/tts-voice/ref.wav + ref.txt (exact transcript)"
    '';
  };
in {
  environment.systemPackages = [cli setup setupBreeze];

  # Socket activation rather than an always-on service or a Claude Code
  # SessionStart hook: nothing is resident while idle, concurrent sessions
  # share one daemon, and systemd owns the lifetime so nothing leaks onto the
  # GPU when a terminal is closed. See wiki: linux/claude-code-tts.
  systemd.user.sockets.kokoro-tts = {
    description = "Kokoro TTS socket (activates the daemon on first connection)";
    wantedBy = ["sockets.target"];
    socketConfig.ListenStream = "127.0.0.1:${toString port}";
  };

  systemd.user.services.kokoro-tts = {
    description = "Kokoro TTS daemon for Claude Code";
    requires = ["kokoro-tts.socket"];
    after = ["kokoro-tts.socket"];
    serviceConfig = {
      Type = "exec";
      # The nvidia driver libs are not on the venv's loader path and nix-ld does
      # not cover them. Without this torch.cuda.is_available() is silently false
      # and synthesis drops to CPU (~20x slower) with no error.
      Environment = [
        "LD_LIBRARY_PATH=/run/opengl-driver/lib"
        "IDLE_TIMEOUT=600"
        # A systemd user service does not inherit the shell's EDITOR, and the
        # UI's "open the output style" button needs one. xdg-open is the fallback.
        "EDITOR=zeditor"
      ];
      ExecStart = "${venv}/bin/python ${daemonSrc}/daemon.py";
    };
  };

  # Not socket-activated: the hooks start it, and it binds its port only once
  # warm (see breeze.py). Exits after IDLE_TIMEOUT or when the last Claude Code
  # session quits, which releases its ~10 GB of VRAM.
  systemd.user.services.breeze-tts = {
    description = "Breeze TTS daemon (cloned voice) for Claude Code";
    # Triton compiles the fast-path kernels at warm-up and needs a C compiler.
    path = [pkgs.gcc pkgs.systemd];
    serviceConfig = {
      Type = "exec";
      Environment = [
        "LD_LIBRARY_PATH=/run/opengl-driver/lib"
        # Triton finds libcuda via /sbin/ldconfig, which NixOS does not have.
        "TRITON_LIBCUDA_PATH=/run/opengl-driver/lib"
        "BREEZE_SRC=${breezeSrc}"
        "BREEZE_MODEL=${breezeModel}"
        "PORT=${toString breezePort}"
        "IDLE_TIMEOUT=600"
      ];
      ExecStart = "${breezeVenv}/bin/python ${daemonSrc}/breeze.py";
    };
  };
}
