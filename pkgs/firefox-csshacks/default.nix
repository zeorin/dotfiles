{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:

stdenvNoCC.mkDerivation {
  pname = "firefox-csshacks";
  version = "0-unstable-2025-12-21";

  src = fetchFromGitHub {
    owner = "MrOtherGuy";
    repo = "firefox-csshacks";
    rev = "ab752a5b27561e61587e54bec0126194794ae2ca";
    hash = "sha256-FVMtbOz0ms5Wob5gzAFpN8g2yw6kGE7rdOY2kmc/o0c=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    cp -R $src $out
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };
}
