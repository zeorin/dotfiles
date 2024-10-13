{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.services.logiops;

in
{
  options = {
    ${namespace}.services.logiops = {
      enable = lib.options.mkOption {
        default = false;
        example = true;
        description = ''
          Enable `logiops`, an unofficial driver for Logitech mice and keyboards.
        '';
        type = lib.types.bool;
      };

      extraConfig = lib.options.mkOption {
        type = lib.types.lines;
        default = "";
        description = ''
          Configuration for `logiops`, see
          <link xlink:href="https://github.com/PixlOne/logiops/wiki/Configuration"/>
          for supported values.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.logiops = {
      description = "Logitech Configuration Daemon";
      startLimitIntervalSec = 0;
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.logiops}/bin/logid";
        User = "root";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "on-failure";
      };
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [ pkgs.logiops ];
    };

    environment.etc."logid.cfg".text = cfg.extraConfig;
  };
}
