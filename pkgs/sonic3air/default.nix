{
  stdenvNoCC,
  fetchurl,
  fetchzip,
  fetchtorrent,
  makeDesktopItem,
  steam-run,
  writeShellScriptBin,
  symlinkJoin,
}:

let
  sonic3airLib = stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "sonic3air_lib";
    version = "24.02.02.0-stable";

    src = fetchzip {
      url = "https://github.com/Eukaryot/sonic3air/releases/download/v${finalAttrs.version}/sonic3air_game.tar.gz";
      hash = "sha256-Sge/8vLTgGfwC120jRRkZAjPJJaMmabrUlrxXn3ROk4=";
    };

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -pv $out/lib/sonic3air

      cp -rv \
        data \
        config.json \
        libdiscord_game_sdk.so \
        sonic3air_linux \
        $out/lib/sonic3air

      cp -v \
        ${finalAttrs.passthru.audioremaster} \
        $out/lib/sonic3air/data/audioremaster.bin

      cp -v \
        ${finalAttrs.passthru.rom}/Sonic_Knuckles_wSonic3.bin \
        $out/lib/sonic3air

      runHook postInstall
    '';

    dontStrip = true;

    desktopItem = makeDesktopItem {
      desktopName = "Sonic 3 A.I.R.";
      name = "Sonic 3 A.I.R.";
      type = "Application";
      exec = "sonic3air_linux";
      comment = finalAttrs.meta.description;
      categories = [
        "Game"
      ];
      icon = "${finalAttrs.src}/data/icon.png";
      terminal = false;
    };

    passthru = {
      rom = fetchtorrent {
        url = "https://archive.org/download/sonic-knuckles-w-sonic-3/sonic-knuckles-w-sonic-3_archive.torrent";
        hash = "sha256-4zZMbL1S4UoYjQzvlmd7kuklHHu/89P6A8mQCLjKDnc=";
      };
      audioremaster = fetchurl {
        url = "https://sonic3air.org/download/audioremaster.bin";
        hash = "sha256-VfRg3Zo1FklOVqvNOeaH//SnUBHWbq/Ng8FJCo4lT6Q=";
      };
    };

    meta = {
      description = "Sonic 3 A.I.R. (Angel Island Revisited)";
    };
  });

  sonic3airBin = writeShellScriptBin "sonic3air_linux" ''
    ${steam-run}/bin/steam-run ${sonic3airLib}/lib/sonic3air/sonic3air_linux "$@"
  '';

in

symlinkJoin {
  pname = "sonic3air";
  inherit (sonic3airLib) version;
  paths = [
    sonic3airLib
    sonic3airBin
  ];
}

# {
#   lib,
#   stdenv,
#   fetchFromGitHub,
#   fetchurl,
#   fetchzip,
#   fetchtorrent,
#   makeDesktopItem,
#   alsa-lib,
#   cmake,
#   curl,
#   libGL,
#   libGLU,
#   libpulseaudio,
#   xorg,
#   autoPatchelfHook,
#   patchelf,
# }:

# stdenv.mkDerivation (finalAttrs: {
#   pname = "sonic3air";
#   version = "24.02.02.0-stable";

#   src = fetchFromGitHub {
#     owner = "Eukaryot";
#     repo = "sonic3air";
#     rev = "v${finalAttrs.version}";
#     hash = "sha256-BYd0tvKP9DGVrthnxJwhsYN8M7O+CbK8WNHTp+/HtIE=";
#   };

#   nativeBuildInputs = [
#     cmake
#     patchelf
#     autoPatchelfHook
#   ];

#   buildInputs = [
#     alsa-lib
#     curl
#     libGL
#     libGLU
#     libpulseaudio
#     xorg.libX11.dev
#     xorg.libXcomposite
#     xorg.libXext
#     xorg.libXxf86vm
#   ];

#   cmakeFlags = [
#     "-DCMAKE_BUILD_TYPE=Release"
#     "-DBUILD_OXYGEN_APP=OFF"
#   ];

#   prePatch = ''
#     substituteInPlace Oxygen/sonic3air/build/_cmake/CMakeLists.txt \
#       --replace "-rpath='$ORIGIN'" ""
#   '';

#   preConfigure = ''
#     pushd Oxygen/sonic3air
#     pushd build/_cmake
#   '';

#   postBuild = ''
#     popd
#   '';

#   installPhase = ''
#     runHook preInstall

#     ./sonic3air_linux -dumpcppdefinitions -nativize
#     ./sonic3air_linux -pack

#     mkdir -pv $out/lib/sonic3air/data

#     mv -v \
#       enginedata.bin \
#       gamedata.bin \
#       audiodata.bin \
#       audioremaster.bin \
#       data/metadata.json \
#       data/images/icon.png \
#       $out/lib/sonic3air/data

#     cp -v \
#       ${finalAttrs.passthru.release}/data/scripts.bin \
#       $out/lib/sonic3air/data
#     chmod -v -x $out/lib/sonic3air/data/scripts.bin

#     mv -v \
#       _master_image_template/config.json \
#       sonic3air_linux \
#       $out/lib/sonic3air

#     cp -v \
#       ${finalAttrs.passthru.rom}/Sonic_Knuckles_wSonic3.bin \
#       $out/lib/sonic3air

#     mkdir -pv $out/lib/discord_game_sdk

#     mv -v \
#       source/external/discord_game_sdk/lib/x86_64/libdiscord_game_sdk.so \
#       $out/lib/discord_game_sdk

#     patchelf --add-rpath '$out/lib/discord_game_sdk' $out/lib/sonic3air/sonic3air_linux

#     mkdir -pv $out/bin

#     ln -s $out/lib/sonic3air/sonic3air_linux $out/bin/sonic3air_linux

#     runHook postInstall
#   '';

#   dontStrip = true;

#   desktopItem = makeDesktopItem {
#     desktopName = "Sonic 3 A.I.R.";
#     name = "Sonic 3 A.I.R.";
#     type = "Application";
#     exec = "sonic3air_linux";
#     comment = finalAttrs.meta.description;
#     categories = [
#       "Game"
#     ];
#     icon = "${finalAttrs.src}/Oxygen/sonic3air/data/images/icon.png";
#     terminal = false;
#   };

#   passthru = {
#     rom = fetchtorrent {
#       url = "https://archive.org/download/sonic-knuckles-w-sonic-3/sonic-knuckles-w-sonic-3_archive.torrent";
#       hash = "sha256-4zZMbL1S4UoYjQzvlmd7kuklHHu/89P6A8mQCLjKDnc=";
#     };
#     audioremaster = fetchurl {
#       url = "https://sonic3air.org/download/audioremaster.bin";
#       hash = "sha256-VfRg3Zo1FklOVqvNOeaH//SnUBHWbq/Ng8FJCo4lT6Q=";
#     };
#     release = fetchzip {
#       url = "https://github.com/Eukaryot/sonic3air/releases/download/v${finalAttrs.version}/sonic3air_game.tar.gz";
#       hash = "sha256-Sge/8vLTgGfwC120jRRkZAjPJJaMmabrUlrxXn3ROk4=";
#     };
#   };

#   meta = {
#     description = "Sonic 3 A.I.R. (Angel Island Revisited)";
#   };
# })
