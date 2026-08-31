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
  daemonSrc = ./../pkgs/kokoro-tts;

  # Shared prelude: read the mutable config layer. Only `mode` is set here —
  # both consumers need it, and shellcheck rejects unused vars in the other.
  readConf = ''
    conf="$HOME/.claude/tts.conf"
    # shellcheck source=/dev/null
    if [ -f "$conf" ]; then source "$conf"; fi
    mode="''${MODE:-gist}"
  '';

  # ponytail: playback is a transient systemd unit rather than a tracked PID.
  # systemd owns the singleton, so "stop the current clip" is one command with
  # no stale-PID race, and a new clip supersedes the old one by unit name.
  playUnit = "claude-tts-play";

  # Stop hook: Claude Code pipes the hook payload in on stdin.
  speak = pkgs.writeShellApplication {
    name = "claude-speak";
    runtimeInputs = [pkgs.jq pkgs.curl pkgs.pipewire pkgs.coreutils pkgs.gnused pkgs.gnugrep pkgs.systemd];
    text = ''
      ${readConf}
      if [ "$mode" = "off" ]; then exit 0; fi
      voice="''${VOICE:-af_heart}"
      speed="''${SPEED:-1.1}"
      fallback_chars="''${FALLBACK_CHARS:-300}"

      transcript=$(jq -r '.transcript_path // empty')
      if [ ! -f "$transcript" ]; then exit 0; fi

      # The Stop hook can fire before Claude Code has flushed the turn's final
      # text entry, which made us speak the *previous* turn. Wait (briefly) for
      # the tail of the transcript to be an assistant text block.
      for _ in 1 2 3 4 5 6 7 8 9 10; do
        tail_type=$(tail -20 "$transcript" | jq -rs '[.[] | select(.type=="assistant")] | last | .message.content[0].type // empty')
        if [ "$tail_type" = "text" ]; then break; fi
        sleep 0.2
      done

      raw=$(jq -rs '[.[] | select(.type=="assistant") | .message.content[]?
                     | select(.type=="text") | .text] | last // empty' "$transcript")

      # In gist mode Claude marks one spoken sentence with a leading 🔊.
      gist=""
      if [ "$mode" = "gist" ]; then
        gist=$(printf '%s' "$raw" | grep -m1 '^[[:space:]]*🔊' | sed 's/^[[:space:]]*🔊[[:space:]]*//' || true)
      fi

      if [ -n "$gist" ]; then
        text="$gist"
      else
        # Fenced code never reaches the ear — that is the read/hear boundary the
        # conversational output style leans on. Markdown and URLs go too.
        # shellcheck disable=SC2016  # the backticks are a sed address for code fences, not a subshell
        clean=$(printf '%s' "$raw" \
          | sed -e '/^```/,/^```/d' -e '/^[[:space:]]*🔊/d' -e 's/[`*_#>|]//g' \
                -e 's|https\?://[^ ]*|link|g' -e 's/^[[:space:]]*-[[:space:]]*/ /' \
          | tr '\n' ' ' | tr -s ' ')
        if [ "$mode" = "conversational" ]; then
          # Written for the ear already; speaking half of it is the bug we fixed.
          text="$clean"
        else
          short=$(printf '%s' "$clean" | head -c "$fallback_chars")
          # prefer to stop on a sentence boundary rather than mid-word
          trimmed=$(printf '%s' "$short" | sed 's/[^.!?]*$//')
          text="''${trimmed:-$short}"
        fi
      fi
      if [ -z "''${text// /}" ]; then exit 0; fi

      # Not mktemp with a trap: playback outlives this hook now, so the file must
      # too. One fixed path is enough — only one clip ever plays at a time.
      wav="''${XDG_RUNTIME_DIR:-/tmp}/claude-tts.wav"
      systemctl --user stop ${playUnit}.service 2>/dev/null || true
      if curl -sf --max-time "''${TIMEOUT:-120}" -o "$wav" \
           -H "X-Voice: $voice" -H "X-Speed: $speed" \
           --data-binary "$text" "http://127.0.0.1:${toString port}"; then
        if [ -s "$wav" ]; then
          systemd-run --user --quiet --collect --unit=${playUnit} \
            --property=Type=exec -- pw-play "$wav" || true
        fi
      fi
    '';
  };

  # UserPromptSubmit hook: two jobs, both cheap. Stop talking the moment Noah
  # submits, and inject the gist instruction while gist mode is on.
  prompt = pkgs.writeShellApplication {
    name = "claude-tts-prompt";
    runtimeInputs = [pkgs.systemd];
    text = ''
      ${readConf}
      systemctl --user stop ${playUnit}.service 2>/dev/null || true
      if [ "$mode" = "gist" ]; then
        printf '%s\n' "''${GIST_PROMPT:-End every reply with a line starting '🔊 ' holding one short spoken-English sentence saying what you did and whether I need to act.}"
      fi
    '';
  };

  shutup = pkgs.writeShellApplication {
    name = "claude-shut-up";
    runtimeInputs = [pkgs.systemd];
    text = ''systemctl --user stop ${playUnit}.service 2>/dev/null || true'';
  };

  config = pkgs.writeShellApplication {
    name = "claude-tts-config";
    runtimeInputs = [pkgs.curl pkgs.xdg-utils];
    text = ''
      # A GET wakes the socket-activated daemon before the browser asks for the page.
      curl -sf --max-time 30 "http://127.0.0.1:${toString port}/config" >/dev/null || true
      xdg-open "http://127.0.0.1:${toString port}/"
    '';
  };

  voices = pkgs.writeShellApplication {
    name = "claude-tts-voices";
    runtimeInputs = [pkgs.jq pkgs.curl pkgs.pipewire];
    text = ''
      if [ "$#" -eq 0 ]; then
        curl -s "http://127.0.0.1:${toString port}/voices" | jq -r '.[]'
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
  environment.systemPackages = [speak prompt shutup config voices setup];

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
}
