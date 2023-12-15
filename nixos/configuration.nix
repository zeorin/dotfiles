# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

let unstable = import <nixos-unstable> { config = config.nixpkgs.config; };

in {
  imports = [
    <nixos-hardware/common/cpu/intel>
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

    kernelParams = [ "quiet" "udev.log_level=3" ];
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
  services.udev.packages = with pkgs; [
    (runCommand "99-ddcci.rules" { } ''
      mkdir -p $out/etc/udev/rules.d
      ln -s ${
        writeText "99-ddcci.rules" ''
          SUBSYSTEM=="i2c-dev", ACTION=="add", \
            ATTR{name}=="NVIDIA i2c adapter*", \
            TAG+="ddcci", \
            TAG+="systemd", \
            ENV{SYSTEMD_WANTS}+="ddcci@$kernel.service"
        ''
      } $out/etc/udev/rules.d/99-ddcci.rules
    '')
    qmk-udev-rules
    vial
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
            pkgs.writeShellScript "attach-ddcci.sh" ''
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
    "v4l2loopback-test-card" = {
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
      DISK_DEVICES = "nvme0n1";
      INTEL_GPU_MIN_FREQ_ON_AC = 300;
      INTEL_GPU_MIN_FREQ_ON_BAT = 300;
      INTEL_GPU_MAX_FREQ_ON_AC = 1150;
      INTEL_GPU_MAX_FREQ_ON_BAT = 850;
      INTEL_GPU_BOOST_FREQ_ON_AC = 1150;
      INTEL_GPU_BOOST_FREQ_ON_BAT = 850;
      NMI_WATCHDOG = 0;
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 70;
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
      SOUND_POWER_SAVE_ON_AC = 0;
      USB_AUTOSUSPEND = 0;
      USB_BLACKLIST_PHONE = 1;
      USB_EXCLUDE_AUDIO = 1;
      USB_EXCLUDE_BTUSB = 1;
      USB_EXCLUDE_PRINTER = 1;
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
  environment.etc."systemd/system-sleep/post-hibernate-pkill-slock.sh".source =
    pkgs.writeShellScript "post-hibernate-pkill-slock.sh" ''
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
    interfaces.enp6s0.useDHCP = true;

    interfaces.enp6s0.wakeOnLan.enable = true;
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

    # NVIDIA drivers
    videoDrivers = [ "nvidia" ];

    serverFlagsSection = ''
      Option "StandbyTime"  "5"
      Option "SuspendTime"  "5"
      Option "OffTime"      "5"
      Option "BlankTime"    "5"
    '';

    screenSection = ''
      Option "DPI" "96 x 96"
    '';

    # extraConfig = ''
    #   # Workaround for Slack Desktop bug: wake lock after playing any media
    #   # https://unix.stackexchange.com/a/707430
    #   Section "Extensions"
    #     Option "MIT-SCREEN-SAVER" "Disable"
    #   EndSection
    # '';

    # Configure keymap in X11
    layout = "us,us";
    xkbVariant = "dvp,";
    xkbOptions =
      "grp:alt_space_toggle,grp_led:scroll,shift:both_capslock_cancel,compose:menu,terminate:ctrl_alt_bksp";

    libinput = {
      enable = true;
      mouse = {
        accelProfile = "adaptive";
        accelSpeed = "1";
      };
    };

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
      setupCommands =
        "${pkgs.xorg.xrandr}/bin/xrandr --output HDMI-0 --auto --output DP-3 --auto --right-of HDMI-0 --primary";
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
  services.interception-tools = with pkgs.interception-tools-plugins; {
    enable = true;
    plugins = [ dual-function-keys ];
    udevmonConfig = ''
      - CMD: ${pkgs.interception-tools}/bin/mux -c dual-function-keys
      - JOB: ${pkgs.interception-tools}/bin/mux -i dual-function-keys | ${dual-function-keys}/bin/dual-function-keys -c ${
        pkgs.writeText "dual-function-keys.yaml" ''
          TIMING:
            DOUBLE_TAP_MILLISEC: 0
          MAPPINGS:
            # Space bar as right alt when held
            - KEY: KEY_SPACE
              TAP: KEY_SPACE
              HOLD: KEY_RIGHTALT
              HOLD_START: BEFORE_CONSUME
            # Caps lock as right ctrl when held, esc when tapped
            - KEY: KEY_CAPSLOCK
              TAP: KEY_ESC
              HOLD: KEY_LEFTCTRL
              HOLD_START: BEFORE_CONSUME
            # Enter as right ctrl when held
            - KEY: KEY_ENTER
              TAP: KEY_ENTER
              HOLD: KEY_RIGHTCTRL
              HOLD_START: BEFORE_CONSUME
            # Right alt as right meta/super when held, compose when tapped
            - KEY: KEY_RIGHTALT
              TAP: KEY_COMPOSE
              HOLD: KEY_RIGHTMETA
              HOLD_START: BEFORE_CONSUME
        ''
      } | ${pkgs.interception-tools}/bin/uinput -c ${
        pkgs.writeText "keyboard-mouse.yaml" ''
          NAME: USB Keyboard Mouse
          PRODUCT: 321
          VENDOR: 1241
          BUSTYPE: BUS_USB
          DRIVER_VERSION: 65537
          EVENTS:
            EV_SYN: [SYN_REPORT, SYN_CONFIG, SYN_MT_REPORT, SYN_DROPPED]
            EV_KEY: [KEY_ESC, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0, KEY_MINUS, KEY_EQUAL, KEY_BACKSPACE, KEY_TAB, KEY_Q, KEY_W, KEY_E, KEY_R, KEY_T, KEY_Y, KEY_U, KEY_I, KEY_O, KEY_P, KEY_LEFTBRACE, KEY_RIGHTBRACE, KEY_ENTER, KEY_LEFTCTRL, KEY_A, KEY_S, KEY_D, KEY_F, KEY_G, KEY_H, KEY_J, KEY_K, KEY_L, KEY_SEMICOLON, KEY_APOSTROPHE, KEY_GRAVE, KEY_LEFTSHIFT, KEY_BACKSLASH, KEY_Z, KEY_X, KEY_C, KEY_V, KEY_B, KEY_N, KEY_M, KEY_COMMA, KEY_DOT, KEY_SLASH, KEY_RIGHTSHIFT, KEY_KPASTERISK, KEY_LEFTALT, KEY_SPACE, KEY_CAPSLOCK, KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F7, KEY_F8, KEY_F9, KEY_F10, KEY_NUMLOCK, KEY_SCROLLLOCK, KEY_KP7, KEY_KP8, KEY_KP9, KEY_KPMINUS, KEY_KP4, KEY_KP5, KEY_KP6, KEY_KPPLUS, KEY_KP1, KEY_KP2, KEY_KP3, KEY_KP0, KEY_KPDOT, KEY_ZENKAKUHANKAKU, KEY_102ND, KEY_F11, KEY_F12, KEY_RO, KEY_KATAKANA, KEY_HIRAGANA, KEY_HENKAN, KEY_KATAKANAHIRAGANA, KEY_MUHENKAN, KEY_KPJPCOMMA, KEY_KPENTER, KEY_RIGHTCTRL, KEY_KPSLASH, KEY_SYSRQ, KEY_RIGHTALT, KEY_HOME, KEY_UP, KEY_PAGEUP, KEY_LEFT, KEY_RIGHT, KEY_END, KEY_DOWN, KEY_PAGEDOWN, KEY_INSERT, KEY_DELETE, KEY_MUTE, KEY_VOLUMEDOWN, KEY_VOLUMEUP, KEY_POWER, KEY_KPEQUAL, KEY_PAUSE, KEY_KPCOMMA, KEY_HANGEUL, KEY_HANJA, KEY_YEN, KEY_LEFTMETA, KEY_RIGHTMETA, KEY_COMPOSE, KEY_STOP, KEY_AGAIN, KEY_PROPS, KEY_UNDO, KEY_FRONT, KEY_COPY, KEY_OPEN, KEY_PASTE, KEY_FIND, KEY_CUT, KEY_HELP, KEY_KPLEFTPAREN, KEY_KPRIGHTPAREN, KEY_F13, KEY_F14, KEY_F15, KEY_F16, KEY_F17, KEY_F18, KEY_F19, KEY_F20, KEY_F21, KEY_F22, KEY_F23, KEY_F24, KEY_UNKNOWN, BTN_LEFT, BTN_RIGHT, BTN_MIDDLE, BTN_SIDE, BTN_EXTRA]
            EV_REL: [REL_X, REL_Y, REL_WHEEL, REL_WHEEL_HI_RES, REL_HWHEEL]
            EV_MSC: [MSC_SCAN]
            EV_REP:
              REP_DELAY: 250
              REP_PERIOD: 33
        ''
      }
      - JOB: ${pkgs.interception-tools}/bin/intercept -g $DEVNODE | ${pkgs.interception-tools}/bin/mux -o dual-function-keys
        DEVICE:
          NAME: .*[Kk]eyboard.*
          LINK: .*-event-kbd
          EVENTS:
            EV_KEY: [KEY_CAPSLOCK, KEY_ENTER, KEY_SPACE, KEY_RIGHTALT]
      - JOB: ${pkgs.interception-tools}/bin/intercept -g $DEVNODE | ${pkgs.interception-tools}/bin/mux -o dual-function-keys
        DEVICE:
          EVENTS:
            EV_KEY: [BTN_LEFT, BTN_TOUCH]
            EV_REL: [REL_WHEEL, REL_WHEEL_HI_RES]
    '';
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

  # i2c
  hardware.i2c.enable = true;

  # Bluetooth support
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Accelerated Video Playback
  hardware.opengl.enable = true;
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    powerManagement.enable = true;
    modesetting.enable = true;
  };
  # nixpkgs.config.cudaSupport = true;
  nixpkgs.config.cudaCapabilities = [ "5.2" ];
  nixpkgs.config.cudaForwardCompat = false;

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
  services.udisks2.enable = true;
  services.devmon.enable = true;

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
    dim-screen = pkgs.writeShellScript "dim-screen.sh" ''
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
  security.pki.certificates = [
    # Kindle for PC 1.17 workaround
    # https://bugs.winehq.org/show_bug.cgi?id=50471
    ''
      -----BEGIN CERTIFICATE-----
      MIIE0zCCA7ugAwIBAgIQGNrRniZ96LtKIVjNzGs7SjANBgkqhkiG9w0BAQUFADCB
      yjELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDlZlcmlTaWduLCBJbmMuMR8wHQYDVQQL
      ExZWZXJpU2lnbiBUcnVzdCBOZXR3b3JrMTowOAYDVQQLEzEoYykgMjAwNiBWZXJp
      U2lnbiwgSW5jLiAtIEZvciBhdXRob3JpemVkIHVzZSBvbmx5MUUwQwYDVQQDEzxW
      ZXJpU2lnbiBDbGFzcyAzIFB1YmxpYyBQcmltYXJ5IENlcnRpZmljYXRpb24gQXV0
      aG9yaXR5IC0gRzUwHhcNMDYxMTA4MDAwMDAwWhcNMzYwNzE2MjM1OTU5WjCByjEL
      MAkGA1UEBhMCVVMxFzAVBgNVBAoTDlZlcmlTaWduLCBJbmMuMR8wHQYDVQQLExZW
      ZXJpU2lnbiBUcnVzdCBOZXR3b3JrMTowOAYDVQQLEzEoYykgMjAwNiBWZXJpU2ln
      biwgSW5jLiAtIEZvciBhdXRob3JpemVkIHVzZSBvbmx5MUUwQwYDVQQDEzxWZXJp
      U2lnbiBDbGFzcyAzIFB1YmxpYyBQcmltYXJ5IENlcnRpZmljYXRpb24gQXV0aG9y
      aXR5IC0gRzUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCvJAgIKXo1
      nmAMqudLO07cfLw8RRy7K+D+KQL5VwijZIUVJ/XxrcgxiV0i6CqqpkKzj/i5Vbex
      t0uz/o9+B1fs70PbZmIVYc9gDaTY3vjgw2IIPVQT60nKWVSFJuUrjxuf6/WhkcIz
      SdhDY2pSS9KP6HBRTdGJaXvHcPaz3BJ023tdS1bTlr8Vd6Gw9KIl8q8ckmcY5fQG
      BO+QueQA5N06tRn/Arr0PO7gi+s3i+z016zy9vA9r911kTMZHRxAy3QkGSGT2RT+
      rCpSx4/VBEnkjWNHiDxpg8v+R70rfk/Fla4OndTRQ8Bnc+MUCH7lP59zuDMKz10/
      NIeWiu5T6CUVAgMBAAGjgbIwga8wDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8E
      BAMCAQYwbQYIKwYBBQUHAQwEYTBfoV2gWzBZMFcwVRYJaW1hZ2UvZ2lmMCEwHzAH
      BgUrDgMCGgQUj+XTGoasjY5rw8+AatRIGCx7GS4wJRYjaHR0cDovL2xvZ28udmVy
      aXNpZ24uY29tL3ZzbG9nby5naWYwHQYDVR0OBBYEFH/TZafC3ey78DAJ80M5+gKv
      MzEzMA0GCSqGSIb3DQEBBQUAA4IBAQCTJEowX2LP2BqYLz3q3JktvXf2pXkiOOzE
      p6B4Eq1iDkVwZMXnl2YtmAl+X6/WzChl8gGqCBpH3vn5fJJaCGkgDdk+bW48DW7Y
      5gaRQBi5+MHt39tBquCWIMnNZBU4gcmU7qKEKQsTb47bDN0lAtukixlE0kF6BWlK
      WE9gyn6CagsCqiUXObXbf+eEZSqVir2G3l6BFoMtEMze/aiCKm0oHw0LxOXnGiYZ
      4fQRbxC1lfznQgUy286dUV4otp6F01vvpX1FQHKOtw5rDgb7MzVIcbidJ4vEZV8N
      hnacRHr2lVz2XTIIM6RUthg/aFzyQkqFOFSDX9HoLPKsEdao7WNq
      -----END CERTIFICATE-----
    ''
  ];

  programs.seahorse.enable = true;
  programs.dconf.enable = true;
  programs.adb.enable = true;
  programs.steam.enable = true;
  programs.gamemode.enable = true;

  environment.shells = [ pkgs.fish ];

  # Move this to home-manager when ready: https://github.com/nix-community/home-manager/issues/1167
  xdg.portal = {
    enable = true;
    configPackages = with pkgs; [ xdg-desktop-portal-gtk ];
  };

  # Enable nix ld
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    fuse3
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
    gdk-pixbuf
    glib
    gtk3
    libGL
    libappindicator-gtk3
    libdrm
    libnotify
    libpulseaudio
    libuuid
    libusb1
    xorg.libxcb
    libxkbcommon
    mesa
    nspr
    nss
    pango
    pipewire
    systemd
    icu
    openssl
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
    xorg.libxkbfile
    xorg.libxshmfence
    zlib
  ];
}
