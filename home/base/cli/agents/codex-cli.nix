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
      version = "0.166.0";
      hash = "1d44b28bc4ac9937d7d3532264baa68a507ce364956a0d4ebb856f331cdee254";
    };
    aarch64-darwin = {
      releasePlatform = "aarch64-apple-darwin";
      version = "0.166.0";
      hash = "55a440cb579f970abe7c79ab181e54b0ea4c419be99f333bbd868eebac9c21f0";
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
