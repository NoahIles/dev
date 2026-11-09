# Every command Claude Code can run by name. `claude` is launched with PATH set
# to exactly this list (the claude package adds its own ripgrep, procps,
# bubblewrap and socat), so anything missing here is "command not found" for
# Claude, its hooks and its status line, even when the system has it.
#
# Claude needs a tool once:  nix shell nixpkgs#foo -c foo ...
# Claude needs it for good:  add a line here, commit, rebuild.
#
# ponytail: PATH is tidiness, not a security boundary (anything in /nix/store
# still runs by absolute path). The boundary is the sandbox in
# configs/claude/settings.json.
{
  config,
  inputs,
  pkgs,
  ...
}: let
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
  ];

  # Borrowed from the running host by name, so the version always matches what
  # is actually installed. A name the host lacks is a dangling link: harmless.
  # ponytail: NixOS paths; a standalone-HM host needs its own dirs here.
  fromHost = {
    "/run/wrappers/bin" = ["sudo"]; # rebuild.sh
    "/etc/profiles/per-user/${config.home.username}/bin" = ["noctalia"];
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

  hostLinks = pkgs.runCommand "claude-host-links" {} ''
    mkdir -p $out/bin
    ${pkgs.lib.concatStrings (pkgs.lib.mapAttrsToList (dir: names: ''
        for n in ${toString names}; do ln -s ${dir}/$n $out/bin/$n; done
      '')
      fromHost)}
  '';

  tools = pkgs.buildEnv {
    name = "claude-tools";
    paths = packages ++ [hostLinks];
    pathsToLink = ["/bin"];
  };

  claude = inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;
in {
  home.packages = [
    (pkgs.writeShellScriptBin "claude" ''
      PATH=${tools}/bin exec ${claude}/bin/claude "$@"
    '')
  ];
}
