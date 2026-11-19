{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
}:

let
  platforms = {
    x86_64-linux = {
      releasePlatform = "x86_64-unknown-linux-musl";
      version = "0.170.0";
      hash = "a77ff87be7ba809d715728270a78f5ce3527dc07529416d1ef8929b90b8475eb";
    };
    aarch64-darwin = {
      releasePlatform = "aarch64-apple-darwin";
      version = "0.170.0";
      hash = "975524bf13aedd1b122d8d0e00c09ee67091b8f688c0b374943dbb3cf22c7893";
    };
  };

  system = stdenv.hostPlatform.system;
  platform = platforms.${system} or (throw "codex-cli: unsupported system ${system}");
in
stdenvNoCC.mkDerivation {
  pname = "codex";
  inherit (platform) version;

  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${platform.version}/codex-package-${platform.releasePlatform}.tar.gz";
    sha256 = platform.hash;
  };

  sourceRoot = ".";
  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  dontBuild = true;
  dontStrip = true;
  dontFixup = stdenv.hostPlatform.isDarwin;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -R bin codex-package.json codex-path codex-resources $out/
    runHook postInstall
  '';

  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  installCheckPhase = ''
    runHook preInstallCheck
    test "$($out/bin/codex --version)" = "codex-cli $version"
    runHook postInstallCheck
  '';

  meta = {
    description = "Lightweight coding agent that runs in your terminal";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    mainProgram = "codex";
    platforms = builtins.attrNames platforms;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
