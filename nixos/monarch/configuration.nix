{
  nixos-hardware,
  lib,
  config,
  pkgs,
  ...
}:

{
  imports = with nixos-hardware.nixosModules; [
    common-pc
    common-pc-ssd
    common-cpu-amd
    common-gpu-nvidia-nonprime
    ./hardware-configuration.nix
    ../common/configuration.nix
  ];

  boot = {
    initrd.luks.devices = {
      cryptroot = {
        device = "/dev/disk/by-uuid/e8131b46-2208-4162-82d1-9097f9dca58a";
        allowDiscards = true;
      };
    };

    # Uncomment for early KMS (better resolution for Plymouth)
    # Requires large boot partition
    # initrd.kernelModules = [
    #   "nvidia"
    #   "nvidia_modeset"
    #   "nvidia_uvm"
    #   "nvidia_drm"
    # ];
    # extraModulePackages = [ config.hardware.nvidia.package ];
    blacklistedKernelModules = [ "nouveau" ];
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

  networking.hostName = "monarch";

  # Don't autostart `keyd`
  systemd.services.keyd.wantedBy = lib.mkForce [ ];

  environment.variables.LIBVA_DRIVER_NAME = "nvidia";
  environment.variables.MOZ_DISABLE_RDD_SANDBOX = "nvidia";

  hardware.nvidia.open = false;

  programs.firefox.enable = true;
  programs.firefox.preferences =
    let
      ffVersion = config.programs.firefox.package.version;
    in
    {
      "media.ffmpeg.vaapi.enabled" = lib.versionOlder ffVersion "137.0.0";
      "media.hardware-video-decoding.force-enabled" = lib.versionAtLeast ffVersion "137.0.0";
      "media.rdd-ffmpeg.enabled" = lib.versionOlder ffVersion "97.0.0";

      "gfx.x11-egl.force-enabled" = true;
      "widget.dmabuf.force-enabled" = true;

      "media.av1.enabled" = false;
    };

  users.groups.uinput.gid = lib.mkForce 984;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.emily = {
    isNormalUser = true;
    description = "Emily Dyer-Schiefer";
    extraGroups = [
      "networkmanager"
      "wheel"
      "lp"
    ];
    packages = with pkgs; [
      audacity
      davinci-resolve
      google-chrome
      maestral-gui
      notion-app
      openshot-qt
      spotify
      telegram-desktop
      zoom-us
      teams-for-linux
    ];
  };
}
