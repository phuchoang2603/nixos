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
      releasePlatform = "linux-x64";
      # renovate: depName=pingdotgg/t3code-linux-x64
      version = "0.1.4";
      hash = "8d759aff8b20f06fd2f4d20653b09b3bdffab88dee7752866582005cb4f031b9";
    };
    aarch64-darwin = {
      releasePlatform = "darwin-arm64";
      # renovate: depName=pingdotgg/t3code-darwin-arm64
      version = "0.1.4";
      hash = "3a13b026366cb7095b845c6419068a21aac766b0160410fe87af1aae4a52cd68";
    };
  };

  system = stdenv.hostPlatform.system;
  platform = platforms.${system} or (throw "t3-cli: unsupported system ${system}");
in
(if stdenv.hostPlatform.isLinux then stdenv else stdenvNoCC).mkDerivation {
  pname = "t3-cli";
  inherit (platform) version;

  src = fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${platform.version}/t3-${platform.version}-${platform.releasePlatform}.tar.gz";
    sha256 = platform.hash;
  };

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  # Bundled fff ships both glibc and musl builds; only the glibc one is loaded.
  autoPatchelfIgnoreMissingDeps = [ "libc.musl-x86_64.so.1" ];

  # The executable carries its JS payload inside the ELF/Mach-O; stripping or
  # re-signing would corrupt it.
  dontStrip = true;
  dontAutoPatchelf = true;
  postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    autoPatchelf $out/libexec/t3/node_modules $out/libexec/t3/resource-monitor
  '';
  dontBuild = true;
  dontFixup = stdenv.hostPlatform.isDarwin;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/libexec/t3 $out/bin
    cp -R t3 client resource-monitor node_modules $out/libexec/t3/
    ln -s $out/libexec/t3/t3 $out/bin/t3
    runHook postInstall
  '';

  meta = {
    description = "T3 Code headless CLI/server, without the desktop app";
    homepage = "https://github.com/pingdotgg/t3code";
    license = lib.licenses.mit;
    mainProgram = "t3";
    platforms = builtins.attrNames platforms;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
