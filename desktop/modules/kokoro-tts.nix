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
  # Everything else — units, daemon, scripts — is declared here.
  venv = "${identity.homeDirectory}/.claude/hooks/tts-venv";
  port = 8765;

  daemon = ./../pkgs/kokoro-tts/daemon.py;

  # Stop hook: Claude Code pipes the hook payload in on stdin.
  speak = pkgs.writeShellApplication {
    name = "claude-speak";
    runtimeInputs = [pkgs.jq pkgs.curl pkgs.pipewire pkgs.coreutils pkgs.gnused];
    text = ''
      conf="$HOME/.claude/tts.conf"
      # shellcheck source=/dev/null
      if [ -f "$conf" ]; then source "$conf"; fi

      enabled="''${ENABLED:-1}"
      voice="''${VOICE:-af_heart}"
      speed="''${SPEED:-1.0}"
      max_chars="''${MAX_CHARS:-300}"
      if [ "$enabled" != "1" ]; then exit 0; fi

      transcript=$(jq -r '.transcript_path // empty')
      if [ ! -f "$transcript" ]; then exit 0; fi

      # last assistant text turn, minus code fences, markdown and URLs
      # shellcheck disable=SC2016  # the backticks are a sed address for code fences, not a subshell
      clean=$(jq -rs '[.[] | select(.type=="assistant") | .message.content[]?
                       | select(.type=="text") | .text] | last // empty' "$transcript" \
        | sed -e '/^```/,/^```/d' -e 's/[`*_#>|]//g' -e 's|https\?://[^ ]*|link|g' \
              -e 's/^[[:space:]]*-[[:space:]]*/ /' \
        | tr '\n' ' ' | tr -s ' ')

      short=$(printf '%s' "$clean" | head -c "$max_chars")
      # prefer to stop on a sentence boundary rather than mid-word
      trimmed=$(printf '%s' "$short" | sed 's/[^.!?]*$//')
      text="''${trimmed:-$short}"
      if [ -z "''${text// /}" ]; then exit 0; fi

      wav=$(mktemp --suffix=.wav)
      trap 'rm -f "$wav"' EXIT
      if curl -sf --max-time "''${TIMEOUT:-120}" -o "$wav" \
           -H "X-Voice: $voice" -H "X-Speed: $speed" \
           --data-binary "$text" "http://127.0.0.1:${toString port}"; then
        if [ -s "$wav" ]; then pw-play "$wav" 2>/dev/null || true; fi
      fi
    '';
  };

  voices = pkgs.writeShellApplication {
    name = "claude-tts-voices";
    runtimeInputs = [pkgs.jq pkgs.curl pkgs.pipewire];
    text = ''
      if [ "$#" -eq 0 ]; then
        curl -s https://huggingface.co/api/models/hexgrad/Kokoro-82M \
          | jq -r '.siblings[].rfilename | select(startswith("voices/"))' \
          | sed 's|voices/||;s|\.pt$||'
        exit 0
      fi
      for v in "$@"; do
        echo "--- $v"
        curl -sf --max-time 120 -H "X-Voice: $v" -H "X-Speed: ''${SPEED:-1.1}" \
          --data-binary "Hi Noah, this is ''${v#??_}. Here is how I sound reading one of Claude's replies." \
          "http://127.0.0.1:${toString port}" | pw-play - 2>/dev/null || true
      done
    '';
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
in {
  environment.systemPackages = [speak voices setup];

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
      ];
      ExecStart = "${venv}/bin/python ${daemon}";
    };
  };
}
