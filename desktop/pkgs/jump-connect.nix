{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  addDriverRunpath,
  alsa-lib,
  dbus,
  libdrm,
  libgbm,
  libGL,
  libpulseaudio,
  libva,
  libxkbcommon,
  pipewire,
  systemd,
  vulkan-loader,
  wayland,
  libx11,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxtst,
  libxcb,
  libxcb-util,
  libxcb-cursor,
  libxcb-image,
  libxcb-keysyms,
  libxcb-render-util,
  libxcb-wm,
  acl,
  pam,
  fontconfig,
  freetype,
  glib,
  zlib,
}:
# ponytail: upstream's prebuilt .deb (Qt 6 is bundled under libexec/jump/lib
# and found through the relative qt.conf, so the tree stays intact). No source
# exists. Self-update (jump-connect-updater shells out to apt/dnf/pacman) and
# the X11 VDI backend can't work here; bump `version` from the apt index
# instead:
# https://jumpdesktop.com/downloads/connect/linux/repos/apt/stable/dists/stable/main/binary-amd64/Packages
stdenv.mkDerivation (finalAttrs: {
  pname = "jump-connect";
  version = "10.17.5";

  src = fetchurl {
    url = "https://jumpdesktop.com/downloads/connect/linux/repos/apt/stable/pool/main/jump-connect_${finalAttrs.version}_amd64.deb";
    hash = "sha256-nVrfsXOBKdWOvBFfqRZHw6DAZAVNADGsmUv5YqNqMhE=";
  };

  nativeBuildInputs = [dpkg autoPatchelfHook];
  buildInputs = [
    stdenv.cc.cc.lib
    acl
    alsa-lib
    dbus
    fontconfig
    freetype
    glib
    libdrm
    libgbm
    libGL
    libpulseaudio
    libva
    libxkbcommon
    pam
    pipewire
    systemd
    vulkan-loader
    wayland
    zlib
    libx11
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxtst
    libxcb
    libxcb-util
    libxcb-cursor
    libxcb-image
    libxcb-keysyms
    libxcb-render-util
    libxcb-wm
  ];
  # dlopen()ed, so never in NEEDED
  runtimeDependencies = [
    libGL
    libgbm
    libpulseaudio
    libva
    pipewire
    vulkan-loader
    wayland
    (lib.getLib systemd)
    addDriverRunpath.driverLink
  ];
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -a usr/libexec usr/share $out/
    rm -rf $out/libexec/jump/xorg-modules $out/libexec/jump/pam
    install -Dm644 usr/lib/udev/rules.d/72-jump-usb.rules -t $out/lib/udev/rules.d
    install -Dm644 usr/lib/tmpfiles.d/jump.conf -t $out/lib/tmpfiles.d
    install -Dm644 usr/lib/systemd/system/jump-connect.service -t $out/lib/systemd/system
    install -Dm644 usr/lib/systemd/user/jump-agent.service -t $out/lib/systemd/user
    substituteInPlace $out/lib/systemd/system/jump-connect.service $out/lib/systemd/user/jump-agent.service \
      $out/share/applications/jump-desktop-connect.desktop \
      --replace-fail /usr/libexec/jump $out/libexec/jump
    mkdir -p $out/bin
    ln -s $out/libexec/jump/jumpconnect $out/bin/jumpconnect
    runHook postInstall
  '';

  meta = {
    description = "Jump Desktop Connect, the remote desktop host agent";
    homepage = "https://jumpdesktop.com/";
    license = lib.licenses.unfree;
    mainProgram = "jumpconnect";
    platforms = ["x86_64-linux"];
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
  };
})
