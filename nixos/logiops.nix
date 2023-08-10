{ config, lib, pkgs, ... }:

with lib;

let cfg = config.services.logiops;
in {
  options.services.logiops = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable `logiops`, an unofficial driver for Logitech mice and keyboards.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Configuration for `logiops`, see
        <link xlink:href="https://github.com/PixlOne/logiops/wiki/Configuration"/>
        for supported values.
      '';
    };
  };

  config = mkIf cfg.enable {
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
