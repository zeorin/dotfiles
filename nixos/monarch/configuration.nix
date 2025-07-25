{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:

{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-pc
    common-pc-ssd
    common-cpu-amd
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

    kernelPackages = pkgs.linuxPackages;
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

  # Enable the GNOME Desktop Environment.
  services.xserver.desktopManager.gnome.enable = true;

  # Don't autostart `keyd`
  systemd.services.keyd.wantedBy = lib.mkForce [ ];

  # Web browsers
  programs.firefox.enable = true;
  programs.chromium.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    inputs.nix-software-center.packages.${system}.nix-software-center
  ];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  services.xserver.videoDrivers = lib.mkForce [ "nvidia" ];
  hardware.nvidia.open = false;
  hardware.nvidia.powerManagement.enable = true;
  hardware.graphics.extraPackages = with pkgs; [ nvidia-vaapi-driver ];
  hardware.graphics.extraPackages32 = with pkgs.pkgsi686Linux; [ nvidia-vaapi-driver ];

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
      teams
    ];
  };
}
