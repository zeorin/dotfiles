{
  modulesPath,
  pkgs,
  config,
  lib,
  ...
}@args:

let
  imcfg = config.i18n.inputMethod;
  cfg = imcfg.ibus;

  ibusModule = (import (modulesPath + "/i18n/input-method/ibus.nix")) (
    args
    // {
      pkgs = pkgs // {
        ibus-with-plugins = pkgs.ibus-with-plugins.override {
          ibus = cfg.package;
        };
      };
    }
  );

in
ibusModule
// {
  disabledModules = (ibusModule.disabledModules or [ ]) ++ [
    "i18n/input-method/ibus.nix"
  ];

  options = {
    i18n.inputMethod.ibus = ibusModule.options.i18n.inputMethod.ibus // {
      package = lib.mkPackageOption pkgs "ibus" { };
    };
  };
}
