{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:

stdenvNoCC.mkDerivation {
  pname = "firefox-csshacks";
  version = "0-unstable-2025-09-22";

  src = fetchFromGitHub {
    owner = "MrOtherGuy";
    repo = "firefox-csshacks";
    rev = "c9cc22f418c794c5efe326aa109eed6427d86543";
    hash = "sha256-oIXXuQI65ZrJFD1/0bmgsJqD1SyjEjZocJvO9YeRqOI=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    cp -R $src $out
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };
}
