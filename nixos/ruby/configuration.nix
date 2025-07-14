# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  nixos-hardware,
  lib,
  config,
  pkgs,
  ...
}:

{
  imports = with nixos-hardware.nixosModules; [
    common-pc-laptop
    common-pc-laptop-ssd
    common-cpu-intel
    ./hardware-configuration.nix
    ../common/configuration.nix
  ];

  networking.hostName = "ruby"; # Define your hostname.

  # Don't autostart `keyd`
  systemd.services.keyd.wantedBy = lib.mkForce [ ];

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
  users.users.kids = {
    isNormalUser = true;
    description = "Kids";
    extraGroups = [
      "networkmanager"
      "lp"
    ];
    packages = with pkgs; [
      google-chrome
      netflix
    ];
  };
}
