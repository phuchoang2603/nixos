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
      version = "0.172.0";
      hash = "63e3b00065ed7f62166d0522e17f663cb866a31d80d03e63365482ed34a1d991";
    };
    aarch64-darwin = {
      releasePlatform = "aarch64-apple-darwin";
      version = "0.172.0";
      hash = "0970016d48209a09c4039139629ed79b4a31c5e3d864e792c043419d98fa6466";
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
