{
  lib,
  config,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.cachix;

in
{
  imports = lib.snowfall.fs.get-non-default-nix-files-recursive ./.;

  options = {
    ${namespace}.cachix = {
      enable = lib.options.mkEnableOption "cachix";
    };
  };

  config = lib.mkIf cfg.enable { nix.settings.substituters = [ "https://cache.nixos.org/" ]; };
}
