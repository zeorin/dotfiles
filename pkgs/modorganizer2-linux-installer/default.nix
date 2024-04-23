{ lib, pkgsCross, stdenvNoCC, fetchFromGitHub, fetchurl, makeDesktopItem, p7zip
, gnome, curl, protontricks, makeWrapper }:

let
  version = "4.6.1";
  src = fetchFromGitHub {
    owner = "rockerbacon";
    repo = "modorganizer2-linux-installer";
    rev = version;
    hash = "sha256-SI1XDWp2uDR1QJx9iGB1F1ixHOMiarHGEvLX6WLo8Zc=";
  };

  steam-redirector = pkgsCross.mingwW64.callPackage ({ stdenv, windows }:
    stdenv.mkDerivation {
      pname = "steam-redirector";
      inherit version;
      src = "${src}/steam-redirector";
      buildInputs = [ windows.mingw_w64_pthreads ];
      installPhase = ''
        mkdir -p $out/bin
        cp main.exe $out/bin
      '';
    }) { };

in stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "modorganizer2-linux-installer";
  inherit version src;
  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    mkdir -p $out/lib $out/bin
    cp -r ./* $out/lib
    cp ${steam-redirector}/bin/main.exe $out/lib/steam-redirector
    makeWrapper $out/lib/install.sh $out/bin/modorganizer2-linux-installer \
      --prefix PATH : "${
        lib.makeBinPath [ p7zip curl gnome.zenity protontricks ]
      }"
  '';
  desktopItem = makeDesktopItem {
    name = finalAttrs.pname;
    desktopName = "Mod Organizer 2 Linux Installer";
    exec = "modorganizer2-linux-installer";
    categories = [ "Game" ];
  };
  meta = with lib; {
    description = "An easy-to-use Mod Organizer 2 installer for Linux";
    homepage = "https://github.com/rockerbacon/modorganizer2-linux-installer";
    mainProgram = "modorganizer2-linux-installer";
    license = licenses.mit;
  };
})
