{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  unstableGitUpdater,
}:

stdenvNoCC.mkDerivation {
  pname = "nordtheme-dircolors";
  version = "unstable-2024-10-19";
  src = fetchFromGitHub {
    owner = "nordtheme";
    repo = "dircolors";
    rev = "0a4906965e2b7b181d2b8f15395dcae2c43ace38";
    hash = "";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -t $out/share/nordtheme/ -Dm644 $src/src/dir_colors

    runHook postInstall
  '';

  passthru.updateScript = unstableGitUpdater { };

  meta = {
    homepage = "https://github.com/nordtheme/dircolors";
    description = "An arctic, north-bluish clean and elegant dircolors theme. ";
    license = with lib.licenses; [ mit ];
    maintainers = with lib.maintainers; [ zeorin ];
    platforms = lib.platforms.all;
  };
}
