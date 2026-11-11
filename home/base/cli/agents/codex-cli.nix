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
      version = "0.167.1";
      hash = "a945df3df83e849dd7b74787e27f8a459c1946b0e3afe3dc8eef8a8d1845fd4f";
    };
    aarch64-darwin = {
      releasePlatform = "aarch64-apple-darwin";
      version = "0.167.0";
      hash = "af45ed45d940d7998809622c1c0296d3098ed7d7fad695284422c228bd454517";
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
