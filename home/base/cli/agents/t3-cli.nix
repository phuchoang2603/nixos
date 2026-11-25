{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  vulkan-loader,
}:

let
  platforms = {
    x86_64-linux = {
      releasePlatform = "linux-x64";
      # renovate: depName=pingdotgg/t3code-linux-x64
      version = "0.1.12";
      hash = "9ba3db46e3554fb9970fd5ede9e823c2f6d6f6763f40340bd4c8ef6b09501c54";
    };
    aarch64-darwin = {
      releasePlatform = "darwin-arm64";
      # renovate: depName=pingdotgg/t3code-darwin-arm64
      version = "0.1.12";
      hash = "1b78c9754160623661c5942a7e22f5a62a64bf1f96ab397f50bbc7c6b6115ca4";
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
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
    vulkan-loader
  ];

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
