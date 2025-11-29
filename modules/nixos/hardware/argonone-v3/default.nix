{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  cfg = config.hardware.argonone-v3;

  mkFanListOption = (
    {
      min,
      max,
      step,
      ...
    }@attrs:
    lib.mkOption (
      {
        type =
          let
            length = (max - min + step) / step;
          in
          with lib.types;
          addCheck (listOf int) (l: (lib.length l) == length && lib.all (x: x >= 30 && x <= 100) l);
      }
      // (lib.removeAttrs attrs [
        "min"
        "max"
        "type"
        "step"
      ])
    )
  );

  # The buttons map to ircodes, don't change their order
  buttons = [
    "POWER"
    "UP"
    "DOWN"
    "LEFT"
    "RIGHT"
    "VOLUMEUP"
    "VOLUMEDOWN"
    "OK"
    "HOME"
    "MENU"
    "BACK"
  ];

  ircodes = [
    "00ff39c6"
    "00ff53ac"
    "00ff4bb4"
    "00ff9966"
    "00ff837c"
    "00ff01fe"
    "00ff817e"
    "00ff738c"
    "00ffd32c"
    "00ffb946"
    "00ff09f6"
  ];

in

{
  disabledModules = [ (modulesPath + "/services/hardware/argonone.nix") ];

  options.hardware.argonone-v3 = {
    enable = lib.options.mkEnableOption "Argon One M.2 Case V3";

    package = lib.mkPackageOption pkgs "argononed" { };

    ir.enable = lib.options.mkEnableOption "Argon One M.2 Case V3 IR remote";

    fans.cpu = mkFanListOption {
      min = 55;
      max = 65;
      step = 5;
      default = [
        30
        55
        100
      ];
    };

    fans.hdd = mkFanListOption {
      min = 30;
      max = 50;
      step = 10;
      default = [
        30
        55
        100
      ];
    };

    kodi-data = lib.mkOption {
      type = lib.types.nullOr lib.types.singleLineStr;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        systemd.services.argonone = {
          enable = true;
          description = "Argon One Fan and Button Service";
          after = [ "multi-user.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "simple";
            Restart = "always";
            RemainAfterExit = true;
            ExecStart = "${cfg.package}/bin/argononed SERVICE";
          };
          restartTriggers = [
            config.environment.etc."argononed.conf".source
            config.environment.etc."argononed-hdd.conf".source
          ];
        };

        hardware.raspberry-pi.config.all = {
          options = {
            usb_max_current_enable = {
              enable = true;
              value = 1;
            };
          };
          base-dt-params = {
            uart0.enable = true;
            uart0.value = "on";

            nvme.enable = true;

            pciex1_gen.enable = true;
            pciex1_gen.value = 3;
          };
        };

        environment.etc."argononed.conf".text = lib.strings.concatStrings (
          lib.imap0 (i: v: "${toString i}=${toString v}") cfg.fans.cpu
        );
        environment.etc."argononed-hdd.conf".text = lib.strings.concatStrings (
          lib.imap0 (i: v: "${toString i}=${toString v}") cfg.fans.hdd
        );
      }

      (lib.mkIf cfg.ir.enable {
        systemd.tmpfiles.settings = lib.mkIf (cfg.kodi-data != null) {
          "10-argonone-kodi-lircmap" = {
            "${cfg.kodi-data}/userdata/Lircmap.xml" = {
              f = {
                mode = "444";
                argument = ''
                  <lircmap>
                    <remote device="argon">
                      <left>KEY_LEFT</left>
                      <right>KEY_RIGHT</right>
                      <up>KEY_UP</up>
                      <down>KEY_DOWN</down>
                      <select>KEY_OK</select>
                      <start>KEY_HOME</start>
                      <rootmenu>KEY_MENU</rootmenu>
                      <back>KEY_BACK</back>
                      <volumeplus>KEY_VOLUMEUP</volumeplus>
                      <volumeminus>KEY_VOLUMEDOWN</volumeminus>
                    </remote>
                  </lircmap>
                '';
              };
            };
          };
        };

        systemd.services.irexec = {
          enable = true;
          description = "Handle events from IR remotes decoded by lircd(8)";
          unitConfig.Documentation = [
            "man:irexec(1)"
            "http://lirc.org/html/configure.html "
            "http://lirc.org/html/configure.html#lircrc_format"
          ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            User = "lirc";
            Type = "simple";
            ExecStart = "${pkgs.lirc}/bin/irexec ${config.environment.etc."lirc/irexec.lircrc".source}";
          };
        };

        environment.etc."lirc/irexec.lircrc".text =
          let
            argon-irexecsh = pkgs.writeShellScript "argon-irexec.sh" ''
              if [ -z "$1" ]; then
                exit
              fi

              amixerdevice=$(${pkgs.alsa-utils}/bin/amixer scontrols | sed -n "s/^.*'\(.*\)'.*$/\1/p")
              if [ $1 == "VOLUMEUP" ]; then
                ${pkgs.alsa-utils}/bin/amixer set $amixerdevice -- $[$(${pkgs.alsa-utils}/bin/amixer get $amixerdevice|grep -o [0-9]*%|sed 's/%//')+5]%
              elif [ $1 == "VOLUMEDOWN" ]; then
                ${pkgs.alsa-utils}/bin/amixer set $amixerdevice -- $[$(${pkgs.alsa-utils}/bin/amixer get $amixerdevice|grep -o [0-9]*%|sed '"'s/%//'"')-5]%
              elif [ $1 == "MUTE" ]; then
                ${pkgs.alsa-utils}/bin/amixer set $amixerdevice toggle
              fi
            '';
          in
          (lib.strings.concatStrings (
            lib.map (key: ''
              begin
                remote=argon
                prog=irexec
                button=KEY_${key}
                config=${argon-irexecsh} "${key}"
              end
            '') buttons
          ));

        services.lirc = {
          enable = true;
          options = ''
            [lircd]
            nodaemon        = False
            driver          = default
            device          = auto
            plugindir       = ${pkgs.lirc}/lib/lirc/plugins
            permission      = 666
            allow-simulate  = No
            repeat-max      = 600
          '';
          configs = [
            ''
              begin remote
                name  argon
                bits           32
                flags SPACE_ENC
                eps            20
                aeps          200

                header       8800  4400
                one           550  1650
                zero          550   550
                ptrail        550
                repeat       8800  2200
                gap          38500
                toggle_bit      0

                frequency    38000

                begin codes
                  ${lib.strings.concatStrings (
                    lib.imap0 (i: button: ''
                      KEY_${button}                0x${lib.elemAt ircodes i}
                    '') buttons
                  )}
                end codes
              end remote
            ''
          ];
        };

        # users.users.lirc.extraGroups = [ "input" ];

        services.udev.extraRules = ''
          # Make the /dev/lirc* devices accessible for users in the group "lirc"
          # using regular group permissions.
          SUBSYSTEM=="lirc", KERNEL=="lirc*", OWNER="lirc", GROUP="lirc", MODE="0660"
        '';

        hardware.i2c.enable = true;

        hardware.raspberry-pi.config.all = {
          dt-overlays = {
            gpio-ir = {
              enable = true;
              params = {
                gpio_pin.enable = true;
                gpio_pin.value = 23;
              };
            };
          };
        };
      })
    ]
  );
}
