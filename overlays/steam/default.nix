# Bugfix for steam client to not inhibit screensaver unless there's a game active
# https://github.com/ValveSoftware/steam-for-linux/issues/5607
# https://github.com/tejing1/nixos-config/blob/master/overlays/steam-fix-screensaver/default.nix

{ ... }:

final: prev: {
  steam = (
    prev.steam.overrideAttrs (
      oldAttrs:
      let
        inherit (builtins) concatStringsSep attrValues mapAttrs;
        inherit (final)
          stdenv
          stdenv_32bit
          runCommandWith
          runCommandLocal
          makeWrapper
          ;
        platforms = {
          x86_64 = 64;
          i686 = 32;
        };
        preloadLibFor =
          bits:
          assert bits == 64 || bits == 32;
          runCommandWith {
            stdenv = if bits == 64 then stdenv else stdenv_32bit;
            runLocal = false;
            name = "filter_SDL_DisableScreenSaver.${toString bits}bit.so";
            derivationArgs = { };
          } "gcc -shared -fPIC -ldl -m${toString bits} -o $out ${./filter_SDL_DisableScreenSaver.c}";
        preloadLibs = runCommandLocal "filter_SDL_DisableScreenSaver" { } (
          concatStringsSep "\n" (
            attrValues (
              mapAttrs (platform: bits: ''
                mkdir -p $out/${platform}
                ln -s ${preloadLibFor bits} $out/${platform}/filter_SDL_DisableScreenSaver.so
              '') platforms
            )
          )
        );
      in
      {
        nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ makeWrapper ];
        buildCommand =
          (oldAttrs.buildCommand or "")
          + ''
            steamBin="$(readlink $out/bin/steam)"
            rm $out/bin/steam
            makeWrapper $steamBin $out/bin/steam --prefix LD_PRELOAD : ${preloadLibs}/\$PLATFORM/filter_SDL_DisableScreenSaver.so
          '';
      }
    )
  );
}
