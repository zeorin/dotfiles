{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:

stdenvNoCC.mkDerivation {
  pname = "firefox-csshacks";
  version = "0-unstable-2025-11-12";

  src = fetchFromGitHub {
    owner = "MrOtherGuy";
    repo = "firefox-csshacks";
    rev = "2f30a2283ba09c5934f474110a8be462482eb272";
    hash = "sha256-aAwiI6+QWPQuEGdz0Ey57RFMakM7XuBYiUJuANxECgM=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    cp -R $src $out
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };
}
