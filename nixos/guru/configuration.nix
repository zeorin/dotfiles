{ inputs, config, lib, pkgs, ... }:

{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-pc
    common-pc-hdd
    common-pc-ssd
    common-cpu-amd
    common-cpu-amd-pstate
    common-gpu-nvidia-nonprime
    ./hardware-configuration.nix
    ../common/configuration.nix
  ];

  nixpkgs.allowUnfreePackages = [
    "hplip"
    "nvidia-x11"
    "nvidia-settings"
    "cuda_cccl"
    "cuda_cudart"
    "cuda_nvcc"
    "libcublas"
    "libcufft"
    "libnpp"
  ];

  nixpkgs.config = {
    # CUDA
    # cudaSupport = true;
    cudaCapabilities = [ "5.2" ];
    cudaForwardCompat = false;
  };

  hardware.firmware = with pkgs;
    [
      rtl8761b-firmware # for Bluetooth USB dongle
    ];

  boot = {
    initrd.luks.devices = {
      cryptroot = {
        device = "/dev/disk/by-uuid/556cb835-419a-48b6-a081-36d2998d9c57";
        allowDiscards = true;
      };
    };

    initrd.network = {
      enable = true;
      ssh = {
        enable = true;
        authorizedKeys = [
          ''
            command="cryptsetup-askpass; exit",no-port-forwarding,no-agent-forwarding ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDJrgSMqVz6MsvsfzY4UhbKi1BZY5o0v6QXPNPCC4xX6NUfwcrkr0NxYHt03ZNAHPzPuocishL93F8JYk0alZaoxEyf9EH+Fcpdxh+RqwCUlRMlGwoKqX/IprTn+DNVtmPi+lw+O/A14GTe9kE5V6PfEmKAJ+JzGMAWmBfCqCbHgzfBFTi/kYQ7FlG/pUl6agtQJe07542nHvea+nkrZy9mcTmhOy90p4w+sttQy1ppyt287Bzc467xAvmpIs3iJTZyt3RCDrNOQUo3z73iY9wxODCIx+wk4Hc4hGgAitsGUHo+HfMJ+bEzQGaYT+Db1mCUIr9ZPsn6nlcD0Mz72scOwZblIlB318pCECOnokwP01D6KY+54r+mx9QlsMS5m3gYxLlU1l1bnaza5YZSVi3Nh05RpM9OvOS8Ap1SzY3Rx50A2WwbNtkGlKBP7gUItKpRMJVCeMlzCGJ+sP3pOTgY2982DisUg3JKkKRBXolpWiWd2VQMM1aB/4f2hL0wky0V+f1OB/ONkp5TGssuVLAYqDda+LyTaeQX4PvTF0DDCKkg55TU8hOx3YNzm7q5gDSHik8rX80FFU3kn7H5zyD18ozAwgM81yHlQgx1nFaVSxaXXViciKPGezjUX5vKHu8L9MOHBwixkIZRK8FbTFodidAmgtxooHnZeh+s7hoZiw== zeorin@monarch''
          ''
            command="cryptsetup-askpass; exit",no-port-forwarding,no-agent-forwarding ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEOq1E9mycw3IYVGBpwEU9Oy9iirB8d5Xyu/+6CiL+mx openpgp:0x3CBFF97B''
        ];
        hostKeys = [
          "/etc/secrets/initrd/ssh_host_rsa_key"
          "/etc/secrets/initrd/ssh_host_ed25519_key"
        ];
      };
    };

    kernelPackages = let
      version = "6.6.1";
      suffix = "zen1"; # use "lqx1" for linux_lqx
    in lib.mkForce (pkgs.linuxPackagesFor (pkgs.linux_zen.override {
      inherit version suffix;
      modDirVersion = lib.versions.pad 3 "${version}-${suffix}";
      src = pkgs.fetchFromGitHub {
        owner = "zen-kernel";
        repo = "zen-kernel";
        rev = "v${version}-${suffix}";
        sha256 = "13m820wggf6pkp351w06mdn2lfcwbn08ydwksyxilqb88vmr0lpq";
      };
    }));
    kernelParams = [ "mem_sleep_default=deep" ];
    extraModulePackages = with config.boot.kernelPackages; [ ddcci-driver ];
    kernelModules = [ "ddcci_backlight" ];
    extraModprobeConfig = ''
      options kvm_amd nested=1
      options kvm ignore_msrs=1 report_ignored_msrs=0
    '';
  };
  services.udev.packages = with pkgs; [ vial ];
  services.udev.extraRules = ''
    SUBSYSTEM=="i2c-dev", ACTION=="add", ATTR{name}=="NVIDIA i2c adapter*", TAG+="ddcci", TAG+="systemd", ENV{SYSTEMD_WANTS}+="ddcci@$kernel.service"
  '';

  systemd.services."ddcci@" = {
    description = "ddcci handler";
    after = [ "graphical.target" ];
    before = [ "shutdown.target" ];
    conflicts = [ "shutdown.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${
          pkgs.writeShellScript "attach-ddcci" ''
            echo "Trying to attach ddcci to $1"
            success=0
            i=0
            id=$(echo $1 | cut -d "-" -f 2)
            while ((success < 1)) && ((i++ < 5)); do
              ${pkgs.ddcutil}/bin/ddcutil getvcp 10 -b $id && {
                success=1
                echo "ddcci 0x37" > /sys/bus/i2c/devices/$1/new_device
                echo "ddcci attached to $1";
              } || sleep 5
            done
          ''
        } %i";
      Restart = "no";
    };
  };

  environment.etc."X11/xorg.conf.d/90-nvidia-i2c.conf".source =
    "${pkgs.ddcutil}/share/ddcutil/data/90-nvidia-i2c.conf";

  fileSystems = { "/".options = [ "noatime" "nodiratime" "discard" ]; };

  services.tlp.settings = {
    SOUND_POWER_SAVE_ON_AC = 0;
    USB_BLACKLIST_PHONE = 1;
    USB_EXCLUDE_BTUSB = 1;
    USB_EXCLUDE_PRINTER = 1;
    WOL_DISABLE = "N";
  };

  networking.hostName = "guru";
  networking.interfaces.enp4s0.wakeOnLan.enable = true;

  # https://github.com/NixOS/nixpkgs/issues/30796#issuecomment-615680290
  services.xserver.displayManager.setupCommands =
    "${pkgs.xorg.xrandr}/bin/xrandr --output HDMI-0 --auto --output DP-1 --auto --right-of HDMI-0 --primary";

  hardware.nvidia.modesetting.enable = true;

  hardware.keyboard.qmk.enable = true;

  # i2c
  hardware.i2c.enable = true;

  services.printing = {
    drivers = [ pkgs.hplipWithPlugin ];
    browsing = true;
    openFirewall = true;
    # this gives access to anyone on the interface you might want to limit it see the official documentation
    allowFrom = [ "all" ];
    defaultShared = true; # If you want
  };

  services.hardware.openrgb.enable = true;
}
