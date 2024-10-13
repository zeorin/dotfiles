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
  options.${namespace}.cachix = {
    enable = lib.options.mkEnableOption "cachix";
  };

  config = lib.mkIf cfg.enable {
    imports = lib.snowfall.fs.get-non-default-nix-files-recursive "./.";
    nix.settings.substituters = [ "https://cache.nixos.org/" ];
  };
}
