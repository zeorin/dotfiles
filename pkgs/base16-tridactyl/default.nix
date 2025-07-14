{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:

stdenvNoCC.mkDerivation {
  pname = "base16-tridactyl";
  version = "0-unstable-2023-01-13";

  src = fetchFromGitHub {
    owner = "tridactyl";
    repo = "base16-tridactyl";
    rev = "448ff5863ea65532f9c7c7b86f7c650fbb1555d2";
    hash = "sha256-Fog7b4qv5HfTtkJ/5eQt1bdWrVMayjvGHpd3LRJSfi4=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    cp -R $src $out
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };
}
