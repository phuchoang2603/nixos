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
      npmPlatform = "linux-x64";
      # renovate: depName=@t3code/t3-linux-x64
      version = "0.1.1-nightly.20261016.3190";
      hash = "sha512-1s1XaTjPxjHn4daTYsPs1zDCjjXvxrzNc/iwLRDs2IZ+IPsHMlLAcmG44HgLUIlaYgd3ECpWQeqvUgDvcn1a/A==";
    };
    aarch64-darwin = {
      npmPlatform = "darwin-arm64";
      # renovate: depName=@t3code/t3-darwin-arm64
      version = "0.1.1-nightly.20261016.3190";
      hash = "sha512-PXauKQYQSFRLbPd6c3KaC7/KPNTaK2H6nv5PbX3CSHa96ZEaDiQlV5N7UkBTDLvQwfi6LaoB/Nn6l8hd4eXL2w==";
    };
  };

  system = stdenv.hostPlatform.system;
  platform = platforms.${system} or (throw "t3-cli: unsupported system ${system}");
in
(if stdenv.hostPlatform.isLinux then stdenv else stdenvNoCC).mkDerivation {
  pname = "t3-cli";
  inherit (platform) version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@t3code/t3-${platform.npmPlatform}/-/t3-${platform.npmPlatform}-${platform.version}.tgz";
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
