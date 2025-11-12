{
  config,
  pkgs,
  lib,
  nixos-raspberrypi,
  ...
}:

{
  # Hardware specific configuration, see section below for a more complete
  # list of modules
  imports = with nixos-raspberrypi.nixosModules; [
    raspberry-pi-5.base
    raspberry-pi-5.page-size-16k
    raspberry-pi-5.display-vc4
  ];

  users.users.nixos.openssh.authorizedKeys.keys = [
    # YOUR SSH PUB KEY HERE #
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEOq1E9mycw3IYVGBpwEU9Oy9iirB8d5Xyu/+6CiL+mx openpgp:0x3CBFF97B"
  ];
  users.users.root.openssh.authorizedKeys.keys = [
    # YOUR SSH PUB KEY HERE #
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEOq1E9mycw3IYVGBpwEU9Oy9iirB8d5Xyu/+6CiL+mx openpgp:0x3CBFF97B"
  ];

  environment.systemPackages = with pkgs; [
    tree
    vim
    git
  ];

  boot.loader.raspberryPi.bootloader = "kernel";

  networking.hostName = "tv";

  system.nixos.tags =
    let
      cfg = config.boot.loader.raspberryPi;
    in
    [
      "raspberry-pi-${cfg.variant}"
      cfg.bootloader
      config.boot.kernelPackages.kernel.version
    ];
}
