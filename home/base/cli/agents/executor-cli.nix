{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  libsecret,
}:

let
  platforms = {
    x86_64-linux = {
      releasePlatform = "linux-x64";
      version = "2.0.0-beta.79";
      hash = "5c0fba1e77db7866b4dcb5addf80f9227c8f917f21c74141d2f9f61176ca9efe";
    };
    aarch64-darwin = {
      releasePlatform = "darwin-arm64";
      version = "2.0.0-beta.79";
      hash = "67e5044549ae3abfd989ab2bcd4e562685da6a8fe6f15374550bff337dab1d48";
    };
  };

  system = stdenv.hostPlatform.system;
  platform = platforms.${system} or (throw "executor-cli: unsupported system ${system}");
in
(if stdenv.hostPlatform.isLinux then stdenv else stdenvNoCC).mkDerivation {
  pname = "executor-cli";
  inherit (platform) version;

  src = fetchurl {
    url = "https://github.com/UsefulSoftwareCo/executor/releases/download/executor%40${platform.version}/executor-${platform.version}-${platform.releasePlatform}.tgz";
    sha256 = platform.hash;
  };

  sourceRoot = "package";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
    libsecret
  ];

  # The executable carries its JS payload inside the binary and loads the
  # runtime directory beside it; stripping or re-signing would corrupt it.
  dontStrip = true;
  dontBuild = true;
  dontFixup = stdenv.hostPlatform.isDarwin;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/libexec/executor $out/bin
    cp -R executor runtime apps packages $out/libexec/executor/
    ln -s $out/libexec/executor/executor $out/bin/executor
    runHook postInstall
  '';

  meta = {
    description = "Executor CLI: local server, tool commands and stdio MCP bridge";
    homepage = "https://executor.sh";
    license = lib.licenses.mit;
    mainProgram = "executor";
    platforms = builtins.attrNames platforms;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
