# Every command Claude Code can run by name: both launchers in claude-box.nix
# start it with PATH set to exactly this list (the claude package adds its own
# ripgrep, procps, bubblewrap and socat), so anything missing here is "command
# not found" for Claude, its hooks and its status line.
#
# This file is data only. The boxed launcher's host-side script
# (claude-outbox) appends to `packages` when a boxed Claude asks for a tool.
#
# ponytail: PATH is tidiness, not a security boundary (anything in /nix/store
# still runs by absolute path). The boundary is the box in claude-box.nix.
{
  pkgs,
  username,
}: {
  # Claude-only: installed for nothing else on the system.
  packages = with pkgs; [
    # shell basics
    bash
    coreutils
    findutils
    diffutils
    gnugrep
    gnused
    gawk
    gnutar
    gzip
    unzip
    which
    less
    # work
    git
    openssh # git over ssh (wiki push)
    curl
    jq
    python3
    # debugging; counted from "command not found" hits in transcripts
    file
    binutils # strings, readelf
    usbutils # lsusb
    pciutils # lspci
    iw
    dnsutils # dig
    poppler-utils # pdftotext; the Read tool renders PDFs with pdftoppm
    grim # screenshots on umbriel/niri
    # claude-outbox:insert (requested tools land above this line)
  ];

  # Borrowed from the running host by name, so the version always matches what
  # is actually installed. A name the host lacks is a dangling link: harmless.
  # ponytail: NixOS paths; a standalone-HM host needs its own dirs here.
  fromHost = {
    "/run/wrappers/bin" = ["sudo"]; # rebuild.sh
    "/etc/profiles/per-user/${username}/bin" = ["noctalia"];
    "/run/current-system/sw/bin" = [
      # nix must match the daemon
      "nix"
      "nix-build"
      "nix-shell"
      "nix-collect-garbage"
      "nixos-rebuild"
      # ~/nixos workflow: Justfile and rebuild.sh
      "just"
      "alejandra"
      "nvd"
      "nom"
      "gamemoderun"
      "notify-send"
      # the desktop Claude is asked to debug
      "systemctl"
      "journalctl"
      "niri"
      "umbriel"
      "nvidia-smi" # is a game running?
      # settings.json hooks call these by name
      "claude-speak"
      "claude-tts-prompt"
      "herdr"
      # TODO(human): the optional power tools. Everything above is needed for
      # Claude to work at all; these are your call.
    ];
  };
}
