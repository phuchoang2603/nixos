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
      releasePlatform = "linux_x64";
      version = "1.5.10";
      hash = "72fb2946d6f5bee3d4e8928fb8a7901104361566619e69d40ae6dc03e094917b";
    };
    aarch64-darwin = {
      releasePlatform = "mac_arm64";
      version = "1.5.10";
      hash = "1470275508c2516b0f208a9050c1572b63b21776d4e7f6bc928a5eb91f3803d2";
    };
  };

  system = stdenv.hostPlatform.system;
  platform = platforms.${system} or (throw "agy-cli: unsupported system ${system}");
in
stdenvNoCC.mkDerivation {
  pname = "antigravity-cli";
  inherit (platform) version;

  src = fetchurl {
    url = "https://github.com/google-antigravity/antigravity-cli/releases/download/${platform.version}/agy_cli_${platform.releasePlatform}.tar.gz";
    sha256 = platform.hash;
  };

  sourceRoot = ".";
  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];
  dontBuild = true;
  # The executable carries its payload inside the binary; stripping would corrupt it.
  dontStrip = true;
  dontFixup = stdenv.hostPlatform.isDarwin;

  installPhase = ''
    runHook preInstall
    install -Dm755 antigravity $out/bin/agy
    runHook postInstall
  '';

  meta = {
    description = "Antigravity agent harness in your terminal";
    homepage = "https://github.com/google-antigravity/antigravity-cli";
    license = lib.licenses.unfree;
    mainProgram = "agy";
    platforms = builtins.attrNames platforms;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
