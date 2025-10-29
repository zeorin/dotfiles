{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:

stdenvNoCC.mkDerivation {
  pname = "firefox-csshacks";
  version = "0-unstable-2025-11-02";

  src = fetchFromGitHub {
    owner = "MrOtherGuy";
    repo = "firefox-csshacks";
    rev = "a7a29f9ac9b8dc5715df18251999d9a5f4db881b";
    hash = "sha256-ktPOQ5z+8oy4JtOUxDx+ynsNHjxnisrNAiV6UW1bGqE=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    cp -R $src $out
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };
}
