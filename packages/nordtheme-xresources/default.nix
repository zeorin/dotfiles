{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  unstableGitUpdater,
}:

stdenvNoCC.mkDerivation {
  pname = "nordtheme-xresources";
  version = "unstable-2024-10-20";
  src = fetchFromGitHub {
    owner = "nordtheme";
    repo = "xresources";
    rev = "2e4d108bcf044d28469e098979bf6294329813fc";
    hash = "sha256-+f3ROQ2/2mh8wmMx0aGP1V0ZZTJH4sr0zyGGO/yLKss=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -t $out/share/nordtheme/xresources -Dm644 $src/src/nord

    runHook postInstall
  '';

  passthru.updateScript = unstableGitUpdater { };

  meta = {
    homepage = "https://github.com/nordtheme/xresources";
    description = "An arctic, north-bluish clean and elegant Xresources color theme.";
    license = with lib.licenses; [ mit ];
    maintainers = with lib.maintainers; [ zeorin ];
    platforms = lib.platforms.all;
  };
}
