{
  inputs,
  config,
  lib,
  pkgs,
  namespace,
  ...
}:

{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-pc
    common-pc-ssd
    common-cpu-amd
    common-cpu-amd-pstate
    common-gpu-amd
    ./hardware-configuration.nix
  ];

  config = {

    ${namespace}.printing.enable = true;

    hardware.firmware = with pkgs; [
      rtl8761b-firmware # for Bluetooth USB dongle
    ];

    boot = {
      initrd = {
        luks.devices = {
          cryptroot = {
            device = "/dev/disk/by-uuid/556cb835-419a-48b6-a081-36d2998d9c57";
            allowDiscards = true;
          };
        };

        availableKernelModules = [ "r8169" ];

        network = {
          enable = true;
          ssh = {
            enable = true;
            port = 22;
            authorizedKeys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEOq1E9mycw3IYVGBpwEU9Oy9iirB8d5Xyu/+6CiL+mx openpgp:0x3CBFF97B"
            ];
            hostKeys = [
              "/etc/secrets/initrd/ssh_host_rsa_key"
              "/etc/secrets/initrd/ssh_host_ed25519_key"
            ];
          };
        };

        # Remote disk unlock
        systemd = {
          network = {
            enable = true;
            networks.ethernet = {
              name = "en*";
              networkConfig = {
                DHCP = "yes";
                MulticastDNS = "yes";
              };
              linkConfig.RequiredForOnline = "routable";
            };
            wait-online.enable = false;
          };
          users.root.shell = "/bin/systemd-tty-ask-password-agent";
        };
      };

      extraModulePackages = with config.boot.kernelPackages; [ ddcci-driver ];
      kernelModules = [
        "ddcci-backlight"
        "nct6775"
      ];
      extraModprobeConfig = ''
        options kvm_amd nested=1
        options kvm ignore_msrs=1 report_ignored_msrs=0
      '';
    };
    services.udev.packages = with pkgs; [ vial ];
    services.udev.extraRules = ''
      SUBSYSTEM=="i2c-dev", ACTION=="add", ATTR{name}=="AMDGPU DM i2c hw bus *", TAG+="ddcci", TAG+="systemd", ENV{SYSTEMD_WANTS}+="ddcci@$kernel.service"
    '';

    # https://gitlab.com/ddcci-driver-linux/ddcci-driver-linux/-/issues/7#note_151296583
    systemd.services."ddcci@" = {
      description = "ddcci handler";
      after = [ "graphical.target" ];
      before = [ "shutdown.target" ];
      conflicts = [ "shutdown.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "attach-ddcci" ''
          echo "Trying to attach ddcci to $1"
          success=0
          i=0
          id=$(echo $1 | cut -d "-" -f 2)
          while ((success < 1)) && ((i++ < 5)); do
            ${pkgs.ddcutil}/bin/ddcutil getvcp 10 -b $id && {
              success=1
              echo "ddcci 0x37" > /sys/bus/i2c/devices/$1/new_device
              echo "ddcci attached to $1";
            } || sleep 5
          done
        ''} %i";
        Restart = "no";
      };
    };

    fileSystems = {
      "/".options = [
        "noatime"
        "nodiratime"
        "discard"
      ];
    };

    services.tlp.settings = {
      SOUND_POWER_SAVE_ON_AC = 0;
      USB_EXCLUDE_PHONE = 1;
      USB_EXCLUDE_BTUSB = 1;
      USB_DENYLIST = lib.concatStringsSep " " [ "03f0:002a" ];
      WOL_DISABLE = "N";
    };

    networking.hostName = "guru";
    networking.interfaces.enp4s0.wakeOnLan.enable = true;

    services.xserver.xrandrHeads = [
      "HDMI-A-0"
      {
        output = "DisplayPort-0";
        primary = true;
      }
    ];

    hardware.amdgpu = {
      opencl.enable = true;
      initrd.enable = true;
      amdvlk.enable = true;
      amdvlk.support32Bit.enable = true;
    };

    hardware.keyboard.qmk.enable = true;

    # i2c
    hardware.i2c.enable = true;

    # hardware.printers.ensureDefaultPrinter = "LaserJet";
    # hardware.printers.ensurePrinters = [{
    #   name = "LaserJet";
    #   description = "HP LaserJet Professional P1102";
    #   location = "Xandor Office";
    #   deviceUri =
    #     "hp:/usb/HP_LaserJet_Professional_P1102?serial=000000000Q836L72PR1a";
    #   model = "drv:///hp/hpcups.drv/hp-laserjet_professional_p1102.ppd";
    # }];
    services.printing.drivers = with pkgs; [ hplipWithPlugin ];
    # Printer sharing
    services.printing.listenAddresses = [ "*:631" ];
    # this gives access to anyone on the interface you might want to limit it see the official documentation
    services.printing.allowFrom = [ "all" ];
    services.printing.browsing = true;
    services.printing.defaultShared = true; # If you want
    services.printing.openFirewall = true;
    services.samba.extraConfig = ''
      load printers = yes
      printing = cups
      printcap name = cups
    '';
    services.samba.shares.printers = {
      comment = "All Printers";
      path = "/var/spool/samba";
      public = "yes";
      browseable = "yes";
      "guest ok" = "yes";
      writable = "no";
      printable = "yes";
      "create mode" = 700;
    };
    systemd.tmpfiles.rules = [ "d /var/spool/samba 1777 root root -" ];

    services.openssh.settings.StreamLocalBindUnlink = true;

    services.hardware.openrgb.enable = true;
    services.hardware.openrgb.package = pkgs.openrgb-with-all-plugins;

    virtualisation.docker.daemon.settings = {
      dns = [ "192.168.0.1" ];
    };
  };
}
