# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ inputs, config, lib, pkgs, ... }:

{
  imports = [ inputs.nixpkgs.nixosModules.notDetected ];

  boot.initrd.availableKernelModules =
    [ "ehci_pci" "ahci" "xhci_pci" "usb_storage" "usbhid" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/757cf7da-9ad2-457a-b402-96e34a21cf42";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/F471-068C";
    fsType = "vfat";
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/eca45b18-eb6d-4110-8cba-af9d54cf9a17"; }];

  nix = {
    settings.max-jobs = lib.mkDefault 4;
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';
  };
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
