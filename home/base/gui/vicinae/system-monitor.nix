{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage {
  name = "store.raycast.raycast-system-monitor";

  src = fetchFromGitHub {
    owner = "raycast";
    repo = "extensions";
    rev = "9c300cc11315347da05b3e22dbe80a23f7f50730";
    sparseCheckout = [ "extensions/system-monitor" ];
    rootDir = "extensions/system-monitor";
    hash = "sha256-cKJkdmPmJk7WnTOYb2zR1+Tcsigc52uRfAFMZWzy0qk=";
  };

  npmDepsHash = "sha256-gH1IZqZkX+SDphpjApySfM6exZ39jSlpiZ665YFpv18=";

  postPatch = ''
    substituteInPlace package.json \
      --replace-fail ' -arch arm64 -arch x86_64' ""
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -r "$HOME/.config/raycast/extensions/"*/. "$out/"
    runHook postInstall
  '';

  meta = {
    description = "System overview for Vicinae via Raycast compatibility";
    homepage = "https://www.raycast.com/hossammourad/raycast-system-monitor";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
  };
}
