# Jellyfin Desktop (Qt + QtWebEngine shell around jellyfin-web, embedded mpv).
# Its own module because the overrides keep growing.
{pkgs, ...}: {
  environment.systemPackages = [
    (pkgs.jellyfin-desktop.overrideAttrs (old: {
      # ponytail: NVIDIA + native Wayland fails to composite mpv's embedded
      # video surface (white screen on playback) — force XWayland instead.
      qtWrapperArgs = old.qtWrapperArgs ++ ["--set QT_QPA_PLATFORM xcb"];
      # ...which means niri sees the XWayland WM_CLASS (`jellyfin-desktop`),
      # not the Wayland app_id, so noctalia's dock can't match the entry.
      postInstall =
        (old.postInstall or "")
        + ''
          substituteInPlace $out/share/applications/*.desktop \
            --replace-fail StartupWMClass=org.jellyfin.JellyfinDesktop \
                           StartupWMClass=jellyfin-desktop
        '';
      # The web UI swallows the wheel, so mpv never sees it (its input.conf
      # does nothing here). Seek from the app's own input plugin instead:
      # down = forward, 2 s per notch, scaled for hi-res wheels; mpv's seekTo
      # is already absolute+exact. Capture phase + stopImmediatePropagation
      # keep the web UI's own wheel handler (volume) from also firing. Rapid
      # ticks add up on a running target, since the reported position lags.
      postPatch =
        (old.postPatch or "")
        + ''
          substituteInPlace native/inputPlugin.js \
            --replace-fail "this.id = 'inputPlugin';" \
                           "this.id = 'inputPlugin'; $(cat ${pkgs.writeText "wheel-seek.js" ''
            let wheelTarget = null, wheelAt = 0;
            window.addEventListener('wheel', (e) => {
              const p = playbackManager._currentPlayer;
              if (!p || p.id !== 'mpvvideoplayer' || !location.hash.startsWith('#/video')) return;
              if (e.target.closest('.dialogContainer, .actionSheet')) return;
              e.preventDefault();
              e.stopImmediatePropagation();
              const now = Date.now();
              if (wheelTarget === null || now - wheelAt > 500) wheelTarget = p.currentTime();
              wheelAt = now;
              const px = e.deltaMode === 1 ? e.deltaY * 100 / 3 : e.deltaY;
              wheelTarget = Math.max(0, wheelTarget + px / 100 * 2000);
              p.currentTime(wheelTarget);
            }, { capture: true, passive: false });
          ''})"
        '';
    }))
  ];
}
