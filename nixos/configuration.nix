# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

let unstable = import <nixos-unstable> { config = config.nixpkgs.config; };

in {
  imports = [
    <nixos-hardware/common/cpu/intel/cpu-only.nix>
    <nixos-hardware/common/gpu/amd>
    <home-manager/nixos>
    ./hardware-configuration.nix
    ./cachix.nix
    ./logiops.nix
  ];

  hardware = {
    enableRedistributableFirmware = true;
    firmware = with pkgs;
      [
        rtl8761b-firmware # for Bluetooth USB dongle
      ];
  };

  boot = {
    # Use the systemd-boot EFI boot loader.
    loader.efi.canTouchEfiVariables = true;
    loader.grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      configurationLimit = 10;
      memtest86.enable = true;
    };

    plymouth.enable = true;

    initrd.luks.devices = {
      cryptkey = {
        device = "/dev/disk/by-uuid/6b17a213-6987-4a8e-b609-5243f6ba1467";
        preLVM = true;
      };
      cryptroot = {
        device = "/dev/disk/by-uuid/556cb835-419a-48b6-a081-36d2998d9c57";
        keyFile = "/dev/mapper/cryptkey";
        preLVM = true;
        allowDiscards = true;
      };
    };

    kernelParams = [ "quiet" "udev.log_level=3" "libata.noacpi=1" ];
    kernelPackages = unstable.linuxPackages_zen;
    extraModulePackages = with config.boot.kernelPackages; [
      # exfat-nofuse
      # akvcam
      v4l2loopback
      ddcci-driver
    ];
    kernelModules = [ "kvm-intel" "v4l2loopback" "ddcci_backlight" ];
    extraModprobeConfig = ''
      options kvm_intel nested=1
      options kvm_intel emulate_invalid_guest_state=0
      options kvm ignore_msrs=1 report_ignored_msrs=0

      options snd-hda-intel power_save=0 power_save_controller=N

      options v4l2loopback devices=1 exclusive_caps=1 video_nr=10 card_label="OBS Camera"
    '';
    supportedFilesystems = [ "ntfs" ];
  };
  services.udev.packages = let
    mkUdevRules = (name: text:
      (pkgs.writeTextFile {
        inherit name;
        text = lib.strings.stringAsChars (x: if x == "\n" then " " else x) text;
        destination = "/etc/udev/rules.d/${name}";
      }));
  in [
    (mkUdevRules "99-ddcci.rules" ''
      SUBSYSTEM=="i2c-dev", ACTION=="add",
        ATTR{name}=="NVIDIA i2c adapter*",
        TAG+="ddcci",
        TAG+="systemd",
        ENV{SYSTEMD_WANTS}+="ddcci@$kernel.service"
    '')
    # https://github.com/NixOS/nixpkgs/issues/226346
    # (mkUdevRules "99-keyd.rules" ''
    #   SUBSYSTEM=="input", ACTION=="add",
    #     ATTR{name}!="keyd virtual*",
    #     RUN+="${pkgs.systemd}/bin/systemctl try-restart keyd.service"
    # '')
    pkgs.vial
  ];
  systemd.services = {
    "ddcci@" = {
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
    v4l2loopback-test-card = {
      description = "OBS Camera test card, shown on timeout";
      after = [ "graphical.target" ];
      before = [ "shutdown.target" ];
      conflicts = [ "shutdown.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart =
          "${config.boot.kernelPackages.v4l2loopback}/bin/v4l2loopback-ctl set-timeout-image -t 3000 /dev/video10 ${
            ./test-card.png
          }";
      };
    };
  };
  environment.etc."X11/xorg.conf.d/90-nvidia-i2c.conf".source =
    "${pkgs.ddcutil}/share/ddcutil/data/90-nvidia-i2c.conf";

  environment.systemPackages = with pkgs; [
    config.boot.kernelPackages.v4l2loopback
    virtiofsd
  ];

  powerManagement.enable = true;
  services.upower.enable = true;
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      NMI_WATCHDOG = 0;
      SOUND_POWER_SAVE_ON_AC = 0;
      WOL_DISABLE = "N";
    };
  };
  services.thermald.enable = true;
  systemd.sleep.extraConfig = "HibernateDelaySec=4h";
  services.logind.lidSwitch = "suspend-then-hibernate";
  services.logind.extraConfig = ''
    HandlePowerKey=hibernate
    HandleSuspendKey=suspend-then-hibernate
    IdleAction=suspend-then-hibernate
    IdleActionSec=1h
  '';
  environment.etc."systemd/system-sleep/post-hibernate-pkill-slock".source =
    pkgs.writeShellScript "post-hibernate-pkill-slock" ''
      if [ "$1-$SYSTEMD_SLEEP_ACTION" = "post-hibernate" ]; then
        ${pkgs.procps}/bin/pkill slock
      fi
    '';

  boot.initrd.network = {
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

  boot.initrd.availableKernelModules = [ "r8169" ];

  fileSystems."/".options = [ "noatime" "nodiratime" "discard" ];

  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/6ee6e25c-fe6f-4c50-b7fb-985260cf8ca9";
    encrypted = {
      enable = true;
      label = "cryptdata";
      blkDev = "/dev/disk/by-uuid/14924ada-f427-411b-b426-e9db44ab0752";
      keyFile = "/dev/mapper/cryptkey";
    };
  };

  networking = {
    hostName = "guru";

    # Easy network config
    networkmanager = {
      enable = true;
      insertNameservers = [
        # Tailscale
        "100.100.100.100"
      ];
    };

    # Enable IPv6
    enableIPv6 = true;

    # The global useDHCP flag is deprecated, therefore explicitly set to false
    # here.  Per-interface useDHCP will be mandatory in the future, so this
    # generated config replicates the default behaviour.
    useDHCP = false;
    interfaces.enp3s0.useDHCP = true;
    interfaces.enp3s0.wakeOnLan.enable = true;
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_ZA.UTF-8";
  console = {
    # font = "Lat2-Terminus16";
    # Nord
    colors = [
      "2E3440"
      "3B4252"
      "434C5E"
      "4C566A"
      "D8DEE9"
      "E5E9F0"
      "ECEFF4"
      "8FBCBB"
      "88C0D0"
      "81A1C1"
      "5E81AC"
      "BF616A"
      "D08770"
      "EBCB8B"
      "A3BE8C"
      "B48EAD"
    ];
    earlySetup = true;
    keyMap = "dvorak-programmer";
  };

  environment.variables = {
    # Hardware acceleration in Firefox
    MOZ_X11_EGL = "1";
  };

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "hplip"
      "steam"
      "steam-original"
      "steam-run"
      "nvidia-x11"
      "nvidia-settings"
      "cuda_cccl"
      "cuda_cudart"
      "cuda_nvcc"
      "libcublas"
      "libcufft"
      "libnpp"
    ];
  nixpkgs.config.packageOverrides = pkgs: {
    slock = (let
      configFile =
        pkgs.writeText "config.h" (builtins.readFile ./slock-config.h);
    in (pkgs.slock.overrideAttrs (oldAttrs: {
      preBuild = "cp ${configFile} config.h";
      patches = (oldAttrs.patches or [ ]) ++ [ ./slock-patches.diff ];
      buildInputs = (oldAttrs.buildInputs or [ ]) ++ [ pkgs.imlib2 ];
    })));
  };

  # Overlays
  nixpkgs.overlays = [
    # Bugfix for steam client to not inhibit screensaver unless there's a game active
    # https://github.com/ValveSoftware/steam-for-linux/issues/5607
    # https://github.com/tejing1/nixos-config/blob/master/overlays/steam-fix-screensaver/default.nix
    (final: prev: {
      steam = (prev.steam.overrideAttrs (oldAttrs:
        let
          inherit (builtins) concatStringsSep attrValues mapAttrs;
          inherit (final)
            stdenv stdenv_32bit runCommandWith runCommandLocal makeWrapper;
          platforms = {
            x86_64 = 64;
            i686 = 32;
          };
          preloadLibFor = bits:
            assert bits == 64 || bits == 32;
            runCommandWith {
              stdenv = if bits == 64 then stdenv else stdenv_32bit;
              runLocal = false;
              name = "filter_SDL_DisableScreenSaver.${toString bits}bit.so";
              derivationArgs = { };
            } "gcc -shared -fPIC -ldl -m${toString bits} -o $out ${
              ./filter_SDL_DisableScreenSaver.c
            }";
          preloadLibs = runCommandLocal "filter_SDL_DisableScreenSaver" { }
            (concatStringsSep "\n" (attrValues (mapAttrs (platform: bits: ''
              mkdir -p $out/${platform}
              ln -s ${
                preloadLibFor bits
              } $out/${platform}/filter_SDL_DisableScreenSaver.so
            '') platforms)));
        in {
          nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ])
            ++ [ makeWrapper ];
          buildCommand = (oldAttrs.buildCommand or "") + ''
            steamBin="$(readlink $out/bin/steam)"
            rm $out/bin/steam
            makeWrapper $steamBin $out/bin/steam --prefix LD_PRELOAD : ${preloadLibs}/\$PLATFORM/filter_SDL_DisableScreenSaver.so
          '';
        }));
    })
  ];

  services.xserver = {
    enable = true;

    serverFlagsSection = ''
      Option "StandbyTime"  "5"
      Option "SuspendTime"  "5"
      Option "OffTime"      "5"
      Option "BlankTime"    "5"
    '';

    screenSection = ''
      Option "DPI" "96 x 96"
    '';

    # Configure keymap in X11
    layout = "us,us";
    xkbVariant = "dvp,";
    xkbOptions = "grp:alt_space_toggle,grp_led:scroll,terminate:ctrl_alt_bksp";

    libinput = {
      enable = true;
      mouse = {
        accelProfile = "adaptive";
        accelSpeed = "1";
      };
    };

    xrandrHeads = [
      "DP-1"
      {
        output = "DP-2";
        primary = true;
      }
    ];

    displayManager = {
      # Log in automatically
      autoLogin.user = "zeorin";
      # https://github.com/NixOS/nixpkgs/issues/174099#issuecomment-1201697954
      sessionCommands = ''
        ${
          lib.getBin pkgs.dbus
        }/bin/dbus-update-activation-environment --systemd --all
      '';
      # https://github.com/NixOS/nixpkgs/issues/30796#issuecomment-615680290
      # We need to create at least one session for auto login to work
      session = [{
        name = "xsession";
        manage = "desktop";
        start = ''
          ${pkgs.runtimeShell} $HOME/.xsession &
          waitPID=$!
        '';
      }];
    };
  };

  # Rebind some keys
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        main = {
          capslock = "overload(control, esc)";
          enter = "overload(control, enter)";
          space = "overload(alt, space)";
          rightalt = "overload(meta, compose)";
          leftcontrol = "overload(nav, toggle(nav))";
          rightcontrol = "overload(nav, toggle(nav))";
        };
        nav = {
          # Like wasd, but aligned with home row
          e = "up";
          s = "left";
          d = "down";
          f = "right";

          # Same thing, but for right hand
          i = "up";
          j = "left";
          k = "down";
          l = "right";

          # hjkl on the Dvorak layout
          c = "down";
          v = "up";
          # j = "left"; # already bound, luckily to the same key
          p = "right";
        };
        shift = {
          leftshift = "capslock";
          rightshift = "capslock";
        };
      };
    };
  };

  # Enable sound.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
  };

  # Location-based stuff
  services.geoclue2.enable = true;
  location.provider = "geoclue2";
  services.localtimed.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.zeorin = {
    isNormalUser = true;
    shell = pkgs.fish;
    group = "zeorin";
    extraGroups = [ "wheel" "networkmanager" "docker" "adbusers" "libvirtd" ];
  };
  users.groups.zeorin = { };
  home-manager.users.zeorin = import ../home-manager/home.nix;

  networking = {
    iproute2.enable = true;
    firewall = {
      allowPing = true;
      allowedTCPPorts = [
        # Printing
        631
        # Calibre wireless
        9090
        # Samba
        5357
        # Syncthing
        22000
      ];
      allowedTCPPortRanges = [
        # KDEConnect
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPorts = [
        # Printing
        631
        # Calibre wireless
        9090
        # Samba
        3702
        # Syncthing
        21027
        22000
      ];
      allowedUDPPortRanges = [
        # KDEConnect
        {
          from = 1714;
          to = 1764;
        }
      ];
    };
  };
  services.samba-wsdd.enable = true;
  services.samba = {
    enable = true;
    openFirewall = true;
    securityType = "user";
    extraConfig = ''
      workgroup = WORKGROUP
      server string = smbnix
      netbios name = smbnix
      security = user
      #use sendfile = yes
      #max protocol = smb2
      # note: localhost is the ipv6 localhost ::1
      hosts allow = 192.168.122. 192.168.0. 127.0.0.1 localhost
      hosts deny = 0.0.0.0/0
      guest account = nobody
      map to guest = bad user
    '';
    shares = {
      public = {
        path = "/mnt/Shares/Public";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "zeorin";
        "force group" = "zeorin";
      };
      private = {
        path = "/mnt/Shares/Private";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "zeorin";
        "force group" = "zeorin";
      };
    };
  };

  services.tailscale.enable = true;

  hardware.keyboard.qmk.enable = true;

  # i2c
  hardware.i2c.enable = true;

  # Bluetooth support
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Accelerated Video Playback
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;

  # Keep the system up-to-date automatically, also prune it from time to time.
  system.autoUpgrade.enable = true;
  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
    };
    optimise.automatic = true;
  };

  # Enable content-addressed derivations and flaxes
  nix.extraOptions = ''
    experimental-features = nix-command flakes ca-derivations
    keep-outputs = true
    keep-derivations = true
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.hplipWithPlugin ];
  services.printing.browsing = true;
  # services.printing.listenAddresses = [
  #   "*:631"
  # ]; # Not 100% sure this is needed and you might want to restrict to the local network
  services.printing.allowFrom = [
    "all"
  ]; # this gives access to anyone on the interface you might want to limit it see the official documentation
  services.printing.defaultShared = true; # If you want

  # Security/crypto
  services.gnome.gnome-keyring.enable = true;

  # Automount USB
  services.gvfs.enable = true;

  # Thumbnail previews for file managers
  services.tumbler.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Enable automatic discovery of the printer from other Linux systems with avahi running.
  services.avahi.enable = true;
  services.avahi.publish.enable = true;
  services.avahi.publish.userServices = true;

  services.logiops = {
    enable = true;
    extraConfig = ''
      devices: ({
        name: "Wireless Mouse MX Master 3";
        smartshift: {
          on: false;
          threshold: 10;
        };
        dpi: 2000;
        thumbwheel: {
          invert: true;
        };
      });
    '';
  };

  programs.fish.enable = true;
  # TODO Move slock setup to home.nix (`services.screen-locker`), if possible,
  # might not be because it's run as root for OOM killer protection
  programs.slock.enable = true;
  programs.xss-lock = let
    dim-screen = pkgs.writeShellScript "dim-screen" ''
      min_brightness=0

      # 60 FPS baby!
      fade_step_time="$(${pkgs.bc}/bin/bc -l <<< "1 / 60")"

      # Set -time and -steps for fading to $min_brightness here. Setting steps
      # to 1 disables fading.
      fade_time=1.5
      fade_steps="$(${pkgs.bc}/bin/bc -l <<< "scale=0; ($fade_time / $fade_step_time) / 1")"

      # Find devices with backlights
      devices=()
      for device in /sys/class/backlight/*; do
        devices+=("$(basename "$device")")
      done

      get_brightness() {
          local device="$1"
          ${pkgs.brightnessctl}/bin/brightnessctl --device="$device" get
      }

      declare -A starting_levels
      for device in "''${devices[@]}"; do
        starting_levels["$device"]="$(get_brightness "$device")"
      done

      set_brightness() {
          local device="$1"
          local level="$2"
          ${pkgs.brightnessctl}/bin/brightnessctl --device="$device" set "$level"
      }

      fade_brightness() {
          local target_level="$1"
          local delta
          local intermediate_level
          for fade_step in $(seq "$fade_steps"); do
              for device in "''${devices[@]}"; do
                delta="$(${pkgs.bc}/bin/bc -l <<< "(''${starting_levels["$device"]} - $target_level) / $fade_steps")"
                intermediate_level="$(${pkgs.bc}/bin/bc -l <<< "scale=0; (''${starting_levels["$device"]} - ($delta * $fade_step)) / 1")"
                set_brightness "$device" "$intermediate_level" &
              done
              sleep "$fade_step_time"
          done
      }

      restore_brightness() {
        for device in "''${devices[@]}"; do
          set_brightness "$device" "''${starting_levels["$device"]}"
        done
      }

      trap "exit 0" TERM INT
      trap "restore_brightness; kill %%" EXIT
      fade_brightness "$min_brightness"
      sleep 2147483647 &
      wait
    '';
  in {
    enable = true;
    lockerCommand = "${config.security.wrapperDir}/slock";
    extraOptions = [ "--notifier=${dim-screen}" ];
  };
  # security.pam.services.hibernate-on-multiple-failures = {
  #   name = "hibernate-on-multiple-failures";
  #   text = ''
  #     auth [success=1 new_authtok_reqd=ok ignore=ignore default=bad] pam_tally2.so onerr=succeed deny=3 even_deny_root unlock_time=30
  #     auth required pam_exec.so ${pkgs.systemd}/bin/systemctl hibernate
  #   '';
  # };
  # security.pam.services.login.text =
  #   lib.mkDefault (lib.mkBefore "auth include hibernate-on-multiple-failures");
  # security.pam.services.slock = {
  #   name = "slock";
  #   text = "auth substack login";
  # };

  programs.seahorse.enable = true;
  programs.dconf.enable = true;
  programs.adb.enable = true;
  programs.steam.enable = true;
  programs.gamemode.enable = true;

  environment.shells = [ pkgs.fish ];

  # Move this to home-manager when ready: https://github.com/nix-community/home-manager/issues/1167
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    configPackages = with pkgs; [ xdg-desktop-portal-gtk ];
    config = { common = { default = [ "gtk" ]; }; };
  };

  # Compatibility for binaries
  services.envfs.enable = true;
  programs.nix-ld.enable = true;
  # https://github.com/Mic92/dotfiles/blob/main/nixos/modules/nix-ld.nix
  programs.nix-ld.libraries = with pkgs; [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    curl
    dbus
    expat
    fontconfig
    freetype
    fuse3
    gdk-pixbuf
    glib
    gtk3
    icu
    libGL
    libappindicator-gtk3
    libdrm
    libglvnd
    libnotify
    libpulseaudio
    libunwind
    libusb1
    libuuid
    libxkbcommon
    libxml2
    mesa
    nspr
    nss
    openssl
    pango
    pipewire
    stdenv.cc.cc
    systemd
    vulkan-loader
    xorg.libX11
    xorg.libXScrnSaver
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libxcb
    xorg.libxkbfile
    xorg.libxshmfence
    zlib
  ];
}
