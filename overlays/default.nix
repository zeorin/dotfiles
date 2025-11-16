# This file defines overlays
{ self, nixpkgs-unstable, ... }:
{
  # This one brings our custom packages from the 'pkgs' directory
  additions =
    final: prev:
    import ../pkgs {
      pkgs = final;
      inherit prev;
    };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
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
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _: {
    unstable = import nixpkgs-unstable {
      inherit (final.stdenv.hostPlatform) system;
      config = final.config // {
        overlays = final.lib.filter (x: x != self.outputs.overlays.unstable-packages) final.config.overlays;
      };
    };
  };
}
