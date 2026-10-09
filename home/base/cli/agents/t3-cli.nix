{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
}:

let
  version = "0.0.46-nightly.20261009.2886";

  platforms = {
    x86_64-linux = {
      npmPlatform = "linux-x64";
      hash = "sha512-hz/+VnpgwO91YUNafT4iGQmm4MibcLByQsguITVAnxRi3UpiWI7raMQudu0Q32TzhR3aDXB8ht02Ku7gp0nPKw==";
    };
    aarch64-darwin = {
      npmPlatform = "darwin-arm64";
      hash = "sha512-1JTEZ4gjBmZ7f2ZenxSsCfz9CCJUWT4UbDrprKZt9giddXiI/5Hy107ySpJWSE1GjBkH+/0W/bIe+YPhwYZteg==";
    };
  };

  system = stdenv.hostPlatform.system;
  platform = platforms.${system} or (throw "t3-cli: unsupported system ${system}");
in
(if stdenv.hostPlatform.isLinux then stdenv else stdenvNoCC).mkDerivation {
  pname = "t3-cli";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@t3code/t3-${platform.npmPlatform}/-/t3-${platform.npmPlatform}-${version}.tgz";
    inherit (platform) hash;
  };

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  # Bundled fff ships both glibc and musl builds; only the glibc one is loaded.
  autoPatchelfIgnoreMissingDeps = [ "libc.musl-x86_64.so.1" ];

  # The executable carries its JS payload inside the ELF/Mach-O; stripping or
  # re-signing would corrupt it.
  dontStrip = true;
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
    description = "T3 Code headless CLI/server (nightly), without the desktop app";
    homepage = "https://github.com/pingdotgg/t3code";
    license = lib.licenses.mit;
    mainProgram = "t3";
    platforms = builtins.attrNames platforms;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
