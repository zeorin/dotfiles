{ inputs, lib, pkgs, ... }:

{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-pc-laptop
    common-pc-laptop-ssd
    common-cpu-intel
    common-cpu-intel-kaby-lake
    common-gpu-intel
    common-hidpi
    ./hardware-configuration.nix
    ../common/configuration.nix
  ];

  dpi = 192;

  hardware.firmware = with pkgs;
    [
      # HP Spectre Bang & Olufsen Speakers
      # https://bugzilla.kernel.org/show_bug.cgi?id=189331#c285
      (runCommandNoCC "firmware-hda-jack-retask" { } ''
        mkdir -p $out/lib/firmware
        cp ${
          writeText "hda-jack-retask.fw" ''
            [codec]
            0x10ec0295 0x103c83b9 0

            [pincfg]
            0x12 0xb7a60130
            0x13 0x40000000
            0x14 0x90170151
            0x16 0x411111f0
            0x17 0x90170152
            0x18 0x411111f0
            0x19 0x03a11040
            0x1a 0x411111f0
            0x1b 0x411111f0
            0x1d 0x40600001
            0x1e 0x220140b0
            0x21 0x03211020
          ''
        } $out/lib/firmware/hda-jack-retask.fw
      '')
    ];

  boot = {
    plymouth.extraConfig = ''
      DeviceScale=2
    '';

    initrd.luks.devices = {
      cryptroot = {
        device = "/dev/disk/by-uuid/e8131b46-2208-4162-82d1-9097f9dca58a";
        allowDiscards = true;
      };
    };

    extraModprobeConfig = ''
      # Fix wifi/bluetooth interference
      # https://askubuntu.com/a/1135543/425119
      options iwlwifi bt_coex_active=Y

      # Fix speakers
      # https://bugzilla.kernel.org/show_bug.cgi?id=189331#c285
      options snd-hda-intel patch=hda-jack-retask.fw,hda-jack-retask.fw,hda-jack-retask.fw,hda-jack-retask.fw
    '';
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/9f5d68c6-57a4-47e0-ba15-d6cfb1e3111c";
      fsType = "ext4";
      options = [ "noatime" "nodiratime" "discard" ];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/8616-069C";
      fsType = "vfat";
    };
  };

  powerManagement.cpuFreqGovernor = "powersave";

  # Generated using https://github.com/intel/dptfxtract
  services.thermald.configFile = ./thermal-conf.xml.auto;
  services.udev.extraRules = ''
    # Adjust screen brightness when AC power is [un]plugged
    SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="${pkgs.brightnessctl}/bin/brightnessctl --device='*' --exponent=4 set 50%-"
    SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${pkgs.brightnessctl}/bin/brightnessctl --device='*' --exponent=4 set 50%+"
    # Suspend the system when battery level drops to 5% or lower
    SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ATTR{capacity}=="[0-5]", RUN+="${pkgs.systemd}/bin/systemctl hibernate"
  '';

  networking.hostName = "monarch";
  networking.interfaces.wlp2s0.useDHCP = true;

  console = {
    packages = with pkgs; [ terminus_font ];
    font = "ter-v32b";
  };

  environment.variables = {
    # HiDPI
    GDK_SCALE = "2";
    GDK_DPI_SCALE = "0.5";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    _JAVA_OPTIONS = "-Dsun.java2d.uiScale=2";
  };

  # Overlays
  nixpkgs.overlays = [
    (_: prev: {
      vaapiIntel = prev.vaapiIntel.override { enableHybridCodec = true; };
    })
  ];

  services.xserver = {
    monitorSection = ''
      DisplaySize   508 286
    '';
    screenSection = ''
      Option "DPI" "192 x 192"
    '';
  };

  # Sensors
  hardware.sensor.iio.enable = true;

  programs.xss-lock = let
    dim-screen = pkgs.writeShellScript "dim-screen" ''
      min_brightness="40%"

      trap "exit 0" TERM INT
      trap "${pkgs.brightnessctl}/bin/brightnessctl --device='*' --restore; kill %%" EXIT
      ${pkgs.brightnessctl}/bin/brightnessctl --device='*' --exponent=4 set "$min_brightness"
      sleep 2147483647 &
      wait
    '';
  in { extraOptions = [ ''--notifier="${dim-screen}"'' ]; };
}
