# This file defines overlays
{ inputs, ... }:
{
  # Add custom packages from the 'pkgs' directory
  additions =
    final: prev:
    let
      pkgs = import ../pkgs { pkgs = prev; };
    in
    pkgs // { tmuxPlugins = prev.tmuxPlugins // pkgs.tmuxPlugins; };

  modifications = final: prev: {
    oama = prev.oama.overrideAttrs (old: {
      nativeBuildInputs = [ final.makeBinaryWrapper ];
      postInstall = ''
        wrapProgram $out/bin/oama \
          --prefix PATH : ${
            final.lib.makeBinPath [
              final.coreutils
              final.libsecret
              final.gnupg
            ]
          }
      '';
    });

    # https://github.com/NixOS/nixpkgs/issues/534670
    openblas = prev.openblas.overrideAttrs (old: {
      doCheck = prev.stdenv.hostPlatform.system != "i686-linux";
    });
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (prev.stdenv.hostPlatform) system;
      inherit (prev) config overlays;
    };
  };
}
