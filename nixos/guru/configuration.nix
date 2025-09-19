{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-pc
    common-pc-ssd
    common-cpu-amd
    common-cpu-amd-pstate
    common-gpu-amd
    ../common/configuration.nix
    ./hardware-configuration.nix
  ];

  nixpkgs.overlays = [
    # https://gitlab.com/ddcci-driver-linux/ddcci-driver-linux/-/merge_requests/17
    (final: prev: {
      linuxPackages_zen = prev.linuxPackages_zen.extend (
        lpself: lpsuper: {
          ddcci-driver = prev.linuxPackages_zen.ddcci-driver.overrideAttrs (oldAttrs: {
            version = prev.linuxPackages_zen.ddcci-driver.version + "-FIXED";

            src = pkgs.fetchFromGitLab {
              owner = "ddcci-driver-linux";
              repo = "ddcci-driver-linux";
              rev = "0233e1ee5eddb4b8a706464f3097bad5620b65f4";
              hash = "sha256-Osvojt8UE+cenOuMoSY+T+sODTAAKkvY/XmBa5bQX88=";
            };

            patches = [
              (pkgs.fetchpatch {
                name = "ddcci-e0605c9cdff7bf3fe9587434614473ba8b7e5f63.patch";
                url = "https://gitlab.com/nullbytepl/ddcci-driver-linux/-/commit/e0605c9cdff7bf3fe9587434614473ba8b7e5f63.patch";
                hash = "sha256-sTq03HtWQBd7Wy4o1XbdmMjXQE2dG+1jajx4HtwBHjM=";
              })
            ];
          });
        }
      );
    })
  ];

  hardware.firmware = with pkgs; [
    rtl8761b-firmware # for Bluetooth USB dongle
  ];

  boot = {
    initrd = {
      luks.devices = {
        cryptroot = {
          device = "/dev/disk/by-uuid/556cb835-419a-48b6-a081-36d2998d9c57";
          allowDiscards = true;
        };
      };

      availableKernelModules = [ "r8169" ];

      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 22;
          authorizedKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEOq1E9mycw3IYVGBpwEU9Oy9iirB8d5Xyu/+6CiL+mx openpgp:0x3CBFF97B"
          ];
          hostKeys = [
            "/etc/secrets/initrd/ssh_host_rsa_key"
            "/etc/secrets/initrd/ssh_host_ed25519_key"
          ];
        };
      };

      # Remote disk unlock
      systemd = {
        network = {
          enable = true;
          networks.ethernet = {
            name = "en*";
            networkConfig = {
              DHCP = "yes";
              MulticastDNS = "yes";
            };
            linkConfig.RequiredForOnline = "routable";
          };
          wait-online.enable = false;
        };
        users.root.shell = "/bin/systemd-tty-ask-password-agent";
      };
    };

    kernelPackages = pkgs.unstable.linuxPackages_zen;
    extraModulePackages = with config.boot.kernelPackages; [ ddcci-driver ];
    kernelModules = [
      "ddcci-backlight"
      "nct6775"
    ];
    extraModprobeConfig = ''
      options kvm_amd nested=1
      options kvm ignore_msrs=1 report_ignored_msrs=0
    '';
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };
  services.udev.packages = with pkgs; [
    vial
    android-udev-rules
    sane-airscan
  ];
  services.udev.extraRules = ''
    SUBSYSTEM=="i2c-dev", ACTION=="add", ATTR{name}=="AMDGPU DM i2c hw bus *", TAG+="ddcci", TAG+="systemd", ENV{SYSTEMD_WANTS}+="ddcci@$kernel.service"
  '';

  # https://gitlab.com/ddcci-driver-linux/ddcci-driver-linux/-/issues/7#note_151296583
  systemd.services."ddcci@" = {
    description = "ddcci handler";
    after = [ "graphical.target" ];
    before = [ "shutdown.target" ];
    conflicts = [ "shutdown.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "attach-ddcci" ''
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
      ''} %i";
      Restart = "no";
    };
  };

  fileSystems = {
    "/".options = [
      "noatime"
      "nodiratime"
      "discard"
    ];
  };

  networking.hostName = "guru";
  networking.interfaces.enp36s0.wakeOnLan.enable = true;

  services.xserver.xrandrHeads = [
    "HDMI-1"
    {
      output = "DP-1";
      primary = true;
    }
  ];

  hardware.amdgpu = {
    opencl.enable = true;
    initrd.enable = true;
    amdvlk.enable = true;
    amdvlk.support32Bit.enable = true;
  };

  environment.systemPackages = with pkgs; [
    lact
    (xsane.override { gimpSupport = true; })
  ];
  systemd.packages = with pkgs; [ lact ];
  systemd.services.lactd.wantedBy = [ "multi-user.target" ];

  systemd.tmpfiles.rules =
    let
      rocmEnv = pkgs.symlinkJoin {
        name = "rocm-combined";
        paths = with pkgs.rocmPackages; [
          rocblas
          hipblas
          clr
        ];
      };
    in
    [
      "L+    /opt/rocm   -    -    -     -    ${rocmEnv}"
    ];

  hardware.keyboard.qmk.enable = true;

  hardware.printers = {
    ensureDefaultPrinter = "Brother_MFC-2340DW";
    ensurePrinters = [
      {
        deviceUri = "ipp://BRN94DDF82613D1.lan/ipp";
        location = "office";
        name = "Brother_MFC-2340DW";
        model = "everywhere";
      }
    ];
  };

  hardware.sane = {
    enable = true;
    openFirewall = true;
    extraBackends = with pkgs; [ sane-airscan ];
    disabledDefaultBackends = [ "escl" ];
  };
  services.saned.enable = true;

  users.users.zeorin.extraGroups = [ "scanner" ];

  users.groups.uinput.gid = lib.mkForce 987;

  # i2c
  hardware.i2c.enable = true;

  services.openssh.settings.StreamLocalBindUnlink = true;

  services.hardware.openrgb.enable = true;
  services.hardware.openrgb.package = pkgs.openrgb-with-all-plugins;

  virtualisation.docker.daemon.settings = {
    dns = [ "192.168.0.1" ];
  };

  # `hostctl` needs to be able to write to this file
  environment.etc.hosts.mode = "0644";
}
