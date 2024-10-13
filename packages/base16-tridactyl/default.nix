{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  unstableGitUpdater,
}:

stdenvNoCC.mkDerivation {
  pname = "base16-tridactyl";
  version = "unstable-2024-10-19";

  src = fetchFromGitHub {
    owner = "tridactyl";
    repo = "base16-tridactyl";
    rev = "448ff5863ea65532f9c7c7b86f7c650fbb1555d2";
    hash = "sha256-Fog7b4qv5HfTtkJ/5eQt1bdWrVMayjvGHpd3LRJSfi4=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -t $out/share/base16-tridactyl/ -Dm644 $src/*.css

    runHook postInstall
  '';

  passthru.updateScript = unstableGitUpdater { };

  meta = {
    homepage = "https://github.com/tridactyl/base16-tridactyl";
    description = "Base16 Themes for the firefox tridactyl plugin";
    license = with lib.licenses; [ mit ];
    maintainers = with lib.maintainers; [ zeorin ];
    platforms = lib.platforms.all;
  };
}
