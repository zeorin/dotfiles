# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:

{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-pc-laptop
    common-pc-laptop-ssd
    common-cpu-intel
    ./hardware-configuration.nix
    ../common/configuration.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages;

  networking.hostName = "ruby"; # Define your hostname.

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
