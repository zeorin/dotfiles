# This file defines overlays
{ inputs, ... }:
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _: import ../pkgs { pkgs = final; };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
    brightnessctl = prev.brightnessctl.overrideAttrs (
      finalAttrs: oldAttrs: {
        version = builtins.substring 0 7 finalAttrs.src.rev;
        src = final.fetchFromGitHub {
          owner = "andeston";
          repo = "brightnessctl";
          rev = "9fdbfa53bcd75373e77c95ae59f683674b28709a";
          hash = "sha256-Ab+H2YIzmNZ47Nk61Maeo4se4GonpqIW0lnqcWhU8qc=";
        };
        postInstall =
          (oldAttrs.postInstall or "")
          + ''
            mkdir -p $out/lib/udev/rules.d
            substitute ${finalAttrs.src}/90-brightnessctl.rules $out/lib/udev/rules.d/90-brightnessctl.rules \
              --replace /bin/chgrp ${final.coreutils}/bin/chgrp \
              --replace /bin/chmod ${final.coreutils}/bin/chmod
          '';
      }
    );
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _: {
    unstable = import inputs.nixpkgs-unstable { inherit (final) system config overlays; };
  };
}
