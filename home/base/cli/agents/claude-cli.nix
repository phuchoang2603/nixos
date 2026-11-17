{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  makeShellWrapper,
  alsa-lib,
  procps,
  ripgrep,
  bubblewrap,
  socat,
  versionCheckHook,
  writableTmpDirAsHomeHook,
}:

let
  platforms = {
    x86_64-linux = {
      releasePlatform = "linux-x64";
      version = "2.1.326";
      hash = "30f5542005d138d74eaba6af8de7a6678e71e87dc4ba929435ac2ff9011d5a53";
    };
    aarch64-darwin = {
      releasePlatform = "darwin-arm64";
      version = "2.1.326";
      hash = "4e27662f58b98ca3c5cbe67081891d2cc86461fbb285c22ed8309078a070671b";
    };
  };

  system = stdenv.hostPlatform.system;
  platform = platforms.${system} or (throw "claude-cli: unsupported system ${system}");
in
stdenvNoCC.mkDerivation {
  pname = "claude-code";
  inherit (platform) version;

  src = fetchurl {
    url = "https://github.com/anthropics/claude-code/releases/download/v${platform.version}/claude-${platform.releasePlatform}.tar.gz";
    sha256 = platform.hash;
  };

  sourceRoot = ".";
  nativeBuildInputs = [
    makeShellWrapper
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];
  dontBuild = true;
  # The executable carries its JS payload inside the binary; stripping would corrupt it.
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m755 claude $out/bin/claude
    wrapProgram $out/bin/claude \
      --set DISABLE_AUTOUPDATER 1 \
      --set-default FORCE_AUTOUPDATE_PLUGINS 1 \
      --set DISABLE_INSTALLATION_CHECKS 1 \
      --set USE_BUILTIN_RIPGREP 0 \
      --set-default CLAUDE_CODE_CERT_STORE bundled,system \
      ${lib.optionalString stdenv.hostPlatform.isLinux "--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ alsa-lib ]} "}--prefix PATH : ${
        lib.makeBinPath (
          [
            procps
            ripgrep
          ]
          ++ lib.optionals stdenv.hostPlatform.isLinux [
            bubblewrap
            socat
          ]
        )
      }
    runHook postInstall
  '';

  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  nativeInstallCheckInputs = [
    writableTmpDirAsHomeHook
    versionCheckHook
  ];
  versionCheckKeepEnvironment = [ "HOME" ];
  versionCheckProgramArg = "--version";

  meta = {
    description = "Agentic coding tool that lives in your terminal";
    homepage = "https://github.com/anthropics/claude-code";
    license = lib.licenses.unfree;
    mainProgram = "claude";
    platforms = builtins.attrNames platforms;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
