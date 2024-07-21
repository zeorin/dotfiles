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
    brightnessctl =
      let
        rev = "3152968fee82796e5d3bac3b49d81e1dd9787850";
      in
      prev.brightnessctl.overrideAttrs (
        finalAttrs: oldAttrs: {
          version = builtins.substring 0 7 rev;
          src = final.fetchFromGitHub {
            owner = "Hummer12007";
            repo = "brightnessctl";
            inherit rev;
            hash = "sha256-zDohA3F+zX9xbS0SGpF0cygPRPN6iXcH1TrRMhoO1qs=";
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
