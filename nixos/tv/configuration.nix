{
  config,
  pkgs,
  lib,
  nixos-raspberrypi,
  self,
  ...
}:

{
  # Hardware specific configuration, see section below for a more complete
  # list of modules
  imports =
    (with nixos-raspberrypi.nixosModules; [
      raspberry-pi-5.base
      raspberry-pi-5.display-vc4
      raspberry-pi-5.bluetooth
      raspberry-pi-5.page-size-16k
    ])
    ++ [
      self.outputs.nixosModules.kodi
      self.outputs.nixosModules.argonone-v3
      ./disko.nix
    ];

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    self.outputs.overlays.additions
    self.outputs.overlays.unstable-packages
  ];

  hardware.bluetooth.enable = true;

  services.kodi = {
    enable = true;
    package = pkgs.kodi-gbm.withPackages (
      p: with p; [
        # Streaming
        youtube
        sponsorblock
        netflix
        formula1

        # Slyguy packages
        # showmax
        # disneyplus
        # nebula

        # Gaming
        joystick
        controller-topology-project
        libretro-genplus
        libretro-nestopia
        libretro-snes9x
      ]
    );
  };

  hardware.argonone-v3 = {
    enable = true;
    ir.enable = true;
    kodi-data = "${config.users.users.kodi.home}/.kodi";
  };

  users.users.zeorin = {
    isNormalUser = true;
    group = "zeorin";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "input"
      "kodi"
    ];
    hashedPassword = "$y$j9T$AOv./oYFZX6l4t0VtG0I41$lMfNpfS/y2.w5r7Y7IQHOjoYuhE68pl5/YnbYCuXhn6";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEOq1E9mycw3IYVGBpwEU9Oy9iirB8d5Xyu/+6CiL+mx openpgp:0x3CBFF97B"
    ];
  };
  users.groups.zeorin = { };

  # Don't require sudo/root to `reboot` or `poweroff`.
  security.polkit.enable = true;

  # Allow passwordless sudo from admin users
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  nix.settings.trusted-users = [ "zeorin" ];
  nix.settings.experimental-features = "nix-command flakes";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = lib.mkForce "no";
    };
  };

  services.udev.extraRules = ''
    # Ignore partitions with "Required Partition" GPT partition attribute
    # On our RPis this is firmware (/boot/firmware) partition
    ENV{ID_PART_ENTRY_SCHEME}=="gpt", \
      ENV{ID_PART_ENTRY_FLAGS}=="0x1", \
      ENV{UDISKS_IGNORE}="1"
  '';

  environment.systemPackages =
    with pkgs;
    let
      retroarch' = (
        retroarch.withCores (
          c: with c; [
            genesis-plus-gx
            nestopia
            snes9x
          ]
        )
      );
    in
    [
      retroarch
      (kodi-retroarch-advanced-launchers.override {
        inherit (retroarch') cores;
      })

      tree
      vim
      git
      raspberrypi-eeprom
      bluez
      bluez-tools
    ];

  boot.loader.raspberryPi.bootloader = "kernel";

  networking.hostName = "tv";
  networking.useNetworkd = true;
  networking.firewall.enable = false;
  # mdns
  networking.firewall.allowedUDPPorts = [ 5353 ];
  systemd.network.networks = {
    "99-ethernet-default-dhcp".networkConfig.MulticastDNS = "yes";
    "99-wireless-client-dhcp".networkConfig.MulticastDNS = "yes";
  };

  # Do not take down the network for too long when upgrading,
  # This also prevents failures of services that are restarted instead of stopped.
  # It will use `systemctl restart` rather than stopping it with `systemctl stop`
  # followed by a delayed `systemctl start`.
  systemd.services = {
    systemd-networkd.stopIfChanged = false;
    # Services that are only restarted might be not able to resolve when resolved is stopped before
    systemd-resolved.stopIfChanged = false;
  };

  # Use iwd instead of wpa_supplicant. It has a user friendly CLI
  networking.networkmanager.wifi.backend = "iwd";
  networking.wireless.iwd = {
    enable = true;
    settings = {
      Network = {
        EnableIPv6 = true;
        RoutePriorityOffset = 300;
      };
      Settings.AutoConnect = true;
    };
  };

  systemd.services.NetworkManager-wait-online.enable = false;
  systemd.network.wait-online.enable = false;

  boot.tmp.useTmpfs = lib.mkForce false;

  time.timeZone = "Africa/Johannesburg";

  console.keyMap = "dvorak-programmer";

  system.stateVersion = "25.05";

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
