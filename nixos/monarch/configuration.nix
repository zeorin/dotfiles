{
  inputs,
  lib,
  config,
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

  nixpkgs.config.allowUnfree = true;

  services.xserver.videoDrivers = lib.mkForce [ "nvidia" ];
  hardware.nvidia.open = false;
  hardware.nvidia.powerManagement.enable = true;

  users.groups.uinput.gid = lib.mkForce 984;

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
}
