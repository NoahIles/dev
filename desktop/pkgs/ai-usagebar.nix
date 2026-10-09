{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  procps,
  xdg-utils,
}:
# ponytail: upstream's prebuilt release ELF rather than its flake
# (github:akitaonrails/ai-usagebar, a buildRustPackage) — it needs nothing but
# libc/libm/libgcc_s, so patchelf is the whole port. Measured 2026-10-09: the
# source build is ~9 min per bump (no binary cache) against ~3 s for this, and
# upstream releases often enough that most `nix flake update`s would pay it.
# Switch to the flake input if a release ever stops shipping x86_64.
stdenv.mkDerivation (finalAttrs: {
  pname = "ai-usagebar";
  version = "1.34.0";

  src = fetchurl {
    url = "https://github.com/akitaonrails/ai-usagebar/releases/download/v${finalAttrs.version}/ai-usagebar-linux-x86_64.tar.gz";
    hash = "sha256-6wJkhK97F9ZSYhMTgaytzgXTnC4oNNtjPmYn83BsZ48=";
  };

  # release tarball is flat (no wrapping directory)
  sourceRoot = ".";

  nativeBuildInputs = [autoPatchelfHook makeWrapper];
  buildInputs = [stdenv.cc.cc.lib];

  installPhase = ''
    runHook preInstall
    install -Dm755 ai-usagebar ai-usagebar-tui -t $out/bin
    runHook postInstall
  '';

  # upstream shells out to pkill and xdg-open; its own flake wraps the same way
  postFixup = ''
    for program in ai-usagebar ai-usagebar-tui; do
      wrapProgram $out/bin/$program \
        --prefix PATH : ${lib.makeBinPath [procps xdg-utils]}
    done
  '';

  meta = {
    description = "Waybar/TUI monitor for Claude, Codex, GLM and OpenRouter plan usage";
    homepage = "https://github.com/akitaonrails/ai-usagebar";
    license = lib.licenses.mit;
    mainProgram = "ai-usagebar";
    platforms = ["x86_64-linux"];
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
  };
})
