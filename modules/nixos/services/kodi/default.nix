{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.services.kodi;

in

{
  options.services.kodi = {
    enable = lib.mkEnableOption "Kodi standalone kiosk service";
    package = lib.mkPackageOption pkgs "kodi-gbm" { };
  };

  config = lib.mkIf cfg.enable {
    systemd.services."kodi@" = {
      enable = true;

      after = [
        # From https://github.com/graysky2/kodi-standalone-service/blob/7037180/x86/init/kodi-gbm.service
        "remote-fs.target"
        "systemd-user-sessions.service"
        "network-online.target"
        "nss-lookup.target"
        "sound.target"
        "bluetooth.target"
        "polkit.service"
        "upower.service"
        "mysqld.service"
        "lircd.service"

        # From `nixpkgs/modules/services/wayland/cage.nix`
        # "systemd-user-sessions.service"
        "plymouth-start.service"
        "plymouth-quit.service"
        "systemd-logind.service"
        "getty@%i.service"
      ];

      before = [
        "graphical.target"
      ];

      wants = [
        # From https://github.com/graysky2/kodi-standalone-service/blob/7037180/x86/init/kodi-gbm.service
        "network-online.target"
        "polkit.service"
        "upower.service"

        # From `nixpkgs/modules/services/wayland/cage.nix`
        "dbus.socket"
        "systemd-login.service"
        "plymouth-quit.service"
      ];

      conflicts = [
        "getty@%i.service"
      ];

      restartIfChanged = false;
      unitConfig.ConditionPathExists = "/dev/tty0";
      serviceConfig = {
        ExecStart = ''
          ${cfg.package}/bin/kodi-standalone
        '';
        ExecStop = ''
          ${pkgs.killall}/bin/killall --exact --wait kodi.bin
        '';

        User = "kodi";

        IgnoreSIGPIPE = "no";

        # Log this user with utmp, letting it show up with commands 'w' and
        # 'who'. This is needed since we replace (a)getty.
        UtmpIdentifier = "%n";
        UtmpMode = "user";
        # A virtual terminal is needed.
        TTYPath = "/dev/%I";
        TTYReset = "yes";
        TTYVHangup = "yes";
        TTYVTDisallocate = "yes";
        # Fail to start if not controlling the virtual terminal.
        StandardInput = "tty-fail";
        StandardOutput = "journal";
        StandardError = "journal";
        # Set up a full (custom) user session for the user
        PAMName = "kodi";
      };

      environment = {
        "LIRC_SOCKET_PATH" = config.passthru.lirc.socket;
      };
    };

    users.users.kodi = {
      isSystemUser = true;
      home = "/var/lib/kodi";
      createHome = true;
      homeMode = "770";
      group = "kodi";
      extraGroups = [
        "audio"
        "input"
        "video"
        "disk"
        "network"
        "tty"
        "render"
        "dialout"
        "gamemode"

        # NixOS doesn't seem to have analogues for the following groups:
        # "optical"
        # "power"
        # "storage"
        "lirc" # I think this might be NixOS's replacement for "optical"
        "i2c"
      ];
    };
    users.groups.kodi = { };

    security.polkit.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
          if (subject.user == "kodi") {
              polkit.log("action=" + action);
              polkit.log("subject=" + subject);
              if (action.id.indexOf("org.freedesktop.login1.") == 0) {
                  return polkit.Result.YES;
              }
              if (action.id.indexOf("org.freedesktop.udisks.") == 0) {
                  return polkit.Result.YES;
              }
              if (action.id.indexOf("org.freedesktop.udisks2.") == 0) {
                  return polkit.Result.YES;
              }
          }
      });
    '';

    security.pam.services.kodi.text = ''
      auth    required pam_unix.so nullok
      account required pam_unix.so
      session required pam_unix.so
      session required pam_env.so conffile=/etc/pam/environment readenv=0
      session required ${config.systemd.package}/lib/security/pam_systemd.so
    '';

    hardware.bluetooth.enable = true;
    hardware.graphics.enable = lib.mkDefault true;

    programs.gamemode.enable = true;

    services.udisks2.enable = true;

    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    systemd.targets.graphical.wants = [ "kodi@tty1.service" ];
    systemd.defaultUnit = "graphical.target";

    services.udev.packages = with pkgs; [ libinput ];
    # TODO: Remove if it works without them
    services.udev.extraRules = ''
      SUBSYSTEM=="vc-sm", GROUP="video", MODE="0660"
      SUBSYSTEM=="vc-sm", GROUP="render", MODE="0660"
      KERNEL=="vchiq", GROUP="video", MODE="0660"
      KERNEL=="vchiq", GROUP="render", MODE="0660"
      SUBSYSTEM=="tty", KERNEL=="tty[0-9]*", GROUP="tty", MODE="0660"

      SUBSYSTEM=="dma_heap", KERNEL=="linux*", GROUP="video", MODE="0660"
      SUBSYSTEM=="dma_heap", KERNEL=="system", GROUP="video", MODE="0660"
      SUBSYSTEM=="dma_heap", KERNEL=="linux*", GROUP="render", MODE="0660"
      SUBSYSTEM=="dma_heap", KERNEL=="system", GROUP="render", MODE="0660"
    '';

    services.dbus.enable = true;

    # From https://github.com/matthewbauer/nixiosk/blob/7e6d1e1/configuration.nix
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
      publish = {
        enable = true;
        userServices = true;
        addresses = true;
        hinfo = true;
        workstation = true;
        domain = true;
      };
    };
    environment.etc."avahi/services/ssh.service" = {
      text = ''
        <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">%h</name>
          <service>
            <type>_ssh._tcp</type>
            <port>22</port>
          </service>
        </service-group>
      '';
    };

    # https://github.com/NixOS/nixpkgs/issues?q=is%3Aissue+flicker-free+boot
    boot.plymouth.enable = true;
    boot.kernelParams = [
      "rd.udev.log_priority=3"
      "vt.global_cursor_default=0"
    ];

    environment.systemPackages = [ cfg.package ];
  };
}
