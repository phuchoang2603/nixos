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
      version = "0.1.9";
      hash = "0141025335da334759cecd8db3483e09772f3600ca03674698524e7d94291362";
    };
    aarch64-darwin = {
      releasePlatform = "darwin-arm64";
      # renovate: depName=pingdotgg/t3code-darwin-arm64
      version = "0.1.9";
      hash = "7d2eb8c0687b70ca03a9d35498381852d3792983589e82d1fb1831c08f0b2301";
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
