{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  fontconfig,
  freetype,
  libGL,
  libx11,
  libxcb,
  libxcursor,
  libxi,
  libxkbcommon,
  libxrandr,
  libxtst,
  zenity,
}:
# ponytail: upstream's prebuilt release ELF, not a source build. It isn't in
# nixpkgs and has no flake, and freya-skia-bindings downloads Skia at build
# time (no network in the sandbox), on top of needing Rust 1.95 and a
# git-branch dependency. Revisit if nixpkgs packages it or Skia gets vendored.
stdenv.mkDerivation (finalAttrs: {
  pname = "orbolay";
  version = "4.0.0";

  src = fetchurl {
    url = "https://github.com/SpikeHD/Orbolay/releases/download/v${finalAttrs.version}/orbolay-x86_64-unknown-linux-gnu";
    hash = "sha256-mpF1A+PiEUBa8hO5mwFj4UNbWgNgXS8EPDGZ1k6Zz9c=";
  };

  # the release asset is the bare ELF
  dontUnpack = true;

  nativeBuildInputs = [autoPatchelfHook makeWrapper];
  buildInputs = [
    stdenv.cc.cc.lib
    fontconfig
    freetype
    libGL
    libx11
    libxcb
    libxtst
  ];
  # winit dlopen()s these, so they never show up in NEEDED
  runtimeDependencies = [
    libxcursor
    libxi
    libxkbcommon
    libxrandr
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/orbolay
    runHook postInstall
  '';

  # Upstream recommends XWayland on Wayland (the overlay needs global window
  # positioning), so hide the Wayland socket and let xwayland-satellite take
  # it. zenity backs the native file dialogs.
  postFixup = ''
    wrapProgram $out/bin/orbolay \
      --set WAYLAND_DISPLAY "" \
      --prefix PATH : ${lib.makeBinPath [zenity]}
  '';

  meta = {
    description = "Discord overlay alternative that works with any client";
    homepage = "https://github.com/SpikeHD/Orbolay";
    license = lib.licenses.gpl3Only;
    mainProgram = "orbolay";
    platforms = ["x86_64-linux"];
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
  };
})
