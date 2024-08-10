{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-pc-laptop
    common-pc-laptop-ssd
    common-cpu-intel
    common-gpu-intel-kaby-lake
    common-hidpi
    ./hardware-configuration.nix
    ../common/configuration.nix
  ];

  dpi = 192;

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
      options snd_hda_intel index=1 model=alc285-hp-spectre-x360
    '';
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/9f5d68c6-57a4-47e0-ba15-d6cfb1e3111c";
      fsType = "ext4";
      options = [
        "noatime"
        "nodiratime"
        "discard"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/8616-069C";
      fsType = "vfat";
    };
  };

  powerManagement.cpuFreqGovernor = "powersave";

  services.thermald = {
    enable = true;
    # Generated using https://github.com/intel/dptfxtract
    configFile = ./thermal-conf.xml.auto;
  };
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
    (_: prev: { vaapiIntel = prev.vaapiIntel.override { enableHybridCodec = true; }; })
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

  programs.xss-lock =
    let
      dim-screen = pkgs.writeShellScript "dim-screen" ''
        min_brightness="40%"

        trap "exit 0" TERM INT
        trap "${pkgs.brightnessctl}/bin/brightnessctl --device='*' --restore; kill %%" EXIT
        ${pkgs.brightnessctl}/bin/brightnessctl --device='*' --exponent=4 set "$min_brightness"
        sleep 2147483647 &
        wait
      '';
    in
    {
      extraOptions = [ ''--notifier="${dim-screen}"'' ];
    };
}
