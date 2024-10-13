{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  unstableGitUpdater,
}:

stdenvNoCC.mkDerivation {
  pname = "firefox-csshacks";
  version = "unstable-2024-10-19";

  src = fetchFromGitHub {
    owner = "MrOtherGuy";
    repo = "firefox-csshacks";
    rev = "831ff094baa329d57c989ccc9fbaebff10e236ed";
    hash = "sha256-B9aDrHCKaAkLgURnXbkPbt2rmdmemhwBPHj7G/lJHck=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/mozilla/firefox

    cp -R $src/chrome $out/share/mozilla/firefox
    cp -R $src/content $out/share/mozilla/firefox

    runHook postInstall
  '';

  passthru.updateScript = unstableGitUpdater { };

  meta = {
    homepage = "https://github.com/MrOtherGuy/firefox-csshacks";
    description = "Collection of random CSS hacks for Firefox";
    license = with lib.licenses; [ mpl20 ];
    maintainers = with lib.maintainers; [ zeorin ];
    platforms = lib.platforms.all;
  };
}
