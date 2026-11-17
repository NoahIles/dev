{
  identity,
  inputs,
  pkgs,
  pkgs-unstable,
  ...
}: {
  # GUI applications and the runtime deps the niri config shells out to.
  # Deliberately separate from desktop.nix, which is the desktop *environment*
  # (compositor, greeter, portals, pipewire) rather than things you launch.
  environment.systemPackages = with pkgs; [
    inputs.luciole.packages.x86_64-linux.default # file manager
    hyprpicker # color picker still need to setup bind
    pastel # paint probably move to another file
    # Screenshot annotator. Its tesseract defaults to every OCR language (~1 GB).
    (inputs.swash.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
      tesseract = pkgs-unstable.tesseract.override {enableLanguages = ["eng"];};
    })
    zathura # PDF Viewer
    imv # Image viewer
    zed-editor # Text editor
    # Theme extension comes from noctalia (modules/noctalia.nix); stays here
    # because it is baked into the package override.
    (inputs.helium-browser.packages.${pkgs.stdenv.hostPlatform.system}.helium.override {
      flags = ["--load-extension=${identity.homeDirectory}/.cache/noctalia/helium-theme"];
    }) # Browser trial
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop
    spotify
    (pkgs-unstable.mailspring.overrideAttrs (old: {
      # ponytail: gnome-keyring *is* running, but Electron picks its password
      # backend from XDG_CURRENT_DESKTOP — `niri` isn't in its list, so it falls
      # back to plaintext and Mailspring refuses to store the password. Name the
      # backend explicitly.
      preFixup =
        (old.preFixup or "")
        + ''
          gappsWrapperArgs+=(--add-flags --password-store=gnome-libsecret)
        '';
    }))
    # flake ships the binary as `zen-beta`; alias it so `zen-browser` (used by
    # niri keybinds) resolves. This is the official stable Zen release.
    (pkgs.writeShellScriptBin "zen-browser" ''exec zen-beta "$@"'')
    (jellyfin-desktop.overrideAttrs (old: {
      # ponytail: NVIDIA + native Wayland fails to composite mpv's embedded
      # video surface (white screen on playback) — force XWayland instead.
      qtWrapperArgs = old.qtWrapperArgs ++ ["--set QT_QPA_PLATFORM xcb"];
      # The web UI swallows the wheel, so mpv never sees it. Seek from the
      # app's own input plugin instead: up = forward, 2 s per notch, scaled
      # for hi-res wheels; mpv's seekTo is already absolute+exact. Rapid
      # ticks add up on a running target, since the reported position lags.
      postPatch =
        (old.postPatch or "")
        + ''
          substituteInPlace native/inputPlugin.js \
            --replace-fail "this.id = 'inputPlugin';" \
                           "this.id = 'inputPlugin'; $(cat ${pkgs.writeText "wheel-seek.js" ''
            let wheelTarget = null, wheelAt = 0;
            document.addEventListener('wheel', (e) => {
              const p = playbackManager._currentPlayer;
              if (!p || p.id !== 'mpvvideoplayer' || !location.hash.startsWith('#/video')) return;
              if (e.target.closest('.dialogContainer, .actionSheet')) return;
              e.preventDefault();
              const now = Date.now();
              if (wheelTarget === null || now - wheelAt > 500) wheelTarget = p.currentTime();
              wheelAt = now;
              const px = e.deltaMode === 1 ? e.deltaY * 100 / 3 : e.deltaY;
              wheelTarget = Math.max(0, wheelTarget - px / 100 * 2000);
              p.currentTime(wheelTarget);
            }, { passive: false });
          ''})"
        '';
      # ...which means niri sees the XWayland WM_CLASS (`jellyfin-desktop`),
      # not the Wayland app_id, so noctalia's dock can't match the entry.
      postInstall =
        (old.postInstall or "")
        + ''
          substituteInPlace $out/share/applications/*.desktop \
            --replace-fail StartupWMClass=org.jellyfin.JellyfinDesktop \
                           StartupWMClass=jellyfin-desktop
        '';
    }))
    vesktop
    # ponytail: FHS/bwrap sandbox (nixpkgs default since 1.0.153) breaks
    # screenshare — PipeWire format negotiation fails with "no more input
    # formats" ~50ms in. Drop the override once upstream fixes it.
    (pkgs-unstable.discord.override {useFHSEnv = false;})
    # Discord overlay for any client. No `input` group for the user on purpose
    # (it lets every process read all keystrokes), so the Ctrl+` keybind and
    # the voice controls stay dead until that is granted.
    (callPackage ../pkgs/orbolay.nix {})
    # ponytail: nixpkgs is still on beta4; drop once it catches up.
    (teamspeak6-client.overrideAttrs (old: rec {
      version = "6.0.0-beta5";
      src = fetchurl {
        url = "https://files.teamspeak-services.com/pre_releases/client/${version}/teamspeak-client.tar.xz";
        hash = "sha256-OURyol7pwkGcRKXnGkAcIb/+zy/csn++IXPQ//0YdaQ=";
      };
      # Claim ts3server:// links here, so the client's own self-written
      # ~/.local/share/applications entry (a duplicate) isn't needed.
      desktopItems = map (d:
        d.override {
          exec = "TeamSpeak %u";
          mimeTypes = ["x-scheme-handler/ts3server" "x-scheme-handler/teamspeak"];
        })
      old.desktopItems;
    }))
    qbittorrent
    kdePackages.kdenlive # Video editor
    mpv
    yazi
    gpu-screen-recorder-gtk
    libnotify
    ffmpegthumbnailer # video thumbnails in nautilus

    # niri config runtime deps
    pavucontrol
    fuzzel
    #swaylock-effects
    brightnessctl
    playerctl
    wl-clipboard
    nautilus
    xwayland-satellite
    obsidian
  ];
}
