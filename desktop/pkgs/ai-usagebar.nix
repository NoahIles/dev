{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:
# ponytail: upstream's prebuilt release ELF rather than buildRustPackage — it
# needs nothing but libc/libm/libgcc_s, so patchelf is the whole port and we
# skip a multi-minute Rust build on every version bump. Switch to
# rustPlatform.buildRustPackage if a release ever stops shipping x86_64.
stdenv.mkDerivation (finalAttrs: {
  pname = "ai-usagebar";
  version = "1.4.0";

  src = fetchurl {
    url = "https://github.com/akitaonrails/ai-usagebar/releases/download/v${finalAttrs.version}/ai-usagebar-linux-x86_64.tar.gz";
    hash = "sha256-PE4yZd0oHfzS0D60cjkgAsgQ3+7dEtfN3gWZs6Lc6uY=";
  };

  # release tarball is flat (no wrapping directory)
  sourceRoot = ".";

  nativeBuildInputs = [autoPatchelfHook];
  buildInputs = [stdenv.cc.cc.lib];

  installPhase = ''
    runHook preInstall
    install -Dm755 ai-usagebar ai-usagebar-tui -t $out/bin
    runHook postInstall
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
