# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

let unstable = import <nixos-unstable> { config = config.nixpkgs.config; };

in {
  imports = [
    <nixos-hardware/common/pc>
    <nixos-hardware/common/pc/hdd>
    <nixos-hardware/common/pc/ssd>
    <nixos-hardware/common/cpu/intel>
    <nixos-hardware/common/cpu/intel/sandy-bridge>
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
    loader = {
      # Use the systemd-boot EFI boot loader.
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
        memtest86.enable = true;
        memtest86.entryFilename = "z-memtest86.conf";
      };
    };

    uvesafb = {
      enable = true;
      gfx-mode = "1920x1080-32";
    };

    plymouth.enable = true;

    initrd.systemd.enable = true;
    initrd.luks.devices = {
      cryptroot = {
        device = "/dev/disk/by-uuid/556cb835-419a-48b6-a081-36d2998d9c57";
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
    kernelModules = [ "kvm-intel" "v4l2loopback" ];
    extraModprobeConfig = ''
      options kvm_intel nested=1
      options kvm_intel emulate_invalid_guest_state=0
      options kvm ignore_msrs=1 report_ignored_msrs=0

      options snd-hda-intel power_save=0 power_save_controller=N model=asus

      options v4l2loopback devices=1 exclusive_caps=1 video_nr=10 card_label="OBS Camera"
    '';
    supportedFilesystems = [ "ntfs" ];
  };
  services.udev.packages = with pkgs; [ vial alsa-utils ];
  services.udev.extraRules = ''
    # https://gitlab.com/ddcci-driver-linux/ddcci-driver-linux/-/issues/18#note_853163044
    ACTION=="add", KERNEL=="snd_seq_dummy", SUBSYSTEM=="module", RUN{builtin}+="kmod load ddcci_backlight"
    # https://github.com/NixOS/nixpkgs/issues/226346#issuecomment-1892314545
    # SUBSYSTEM=="input", ACTION=="add", ATTR{name}!="keyd virtual*", RUN+="${pkgs.systemd}/bin/systemctl try-restart keyd.service"
  '';
  systemd.services = {
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
    alsa-utils
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

  fileSystems."/boot".options = [ "uid=0" "gid=0" "fmask=0077" "dmask=0077" ];

  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/6ee6e25c-fe6f-4c50-b7fb-985260cf8ca9";
    encrypted = {
      enable = true;
      label = "cryptdata";
      blkDev = "/dev/disk/by-uuid/14924ada-f427-411b-b426-e9db44ab0752";
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

    videoDrivers = [ "ati" ];

    deviceSection = ''
      Option "SWCursor"
    '';

    serverFlagsSection = ''
      Option "StandbyTime"  "10"
      Option "SuspendTime"  "10"
      Option "OffTime"      "10"
      Option "BlankTime"    "10"
    '';

    # Configure keymap in X11
    layout = "us,us";
    xkbVariant = "dvp,";
    xkbOptions = "grp:alt_space_toggle,grp_led:scroll,terminate:ctrl_alt_bksp";

    libinput.touchpad = {
      disableWhileTyping = true;
      naturalScrolling = true;
    };

    xrandrHeads = [
      "DisplayPort-0"
      {
        output = "DisplayPort-1";
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
        global.layer_indicator = 1;
        main = {
          capslock = "overload(control, esc)";
          enter = "overload(control, enter)";
          space = "overload(alt, space)";
          rightalt = "overload(meta, compose)";
          leftcontrol = "overload(nav, oneshot(nav))";
          rightcontrol = "overload(nav, oneshot(nav))";
        };
        nav = {
          leftcontrol = "toggle(nav)";
          rightcontrol = "toggle(nav)";

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
  systemd.services.alsa-store = {
    description = "Store Sound Card State";
    wantedBy = [ "multi-user.target" ];
    unitConfig.RequiresMountsFor = "/var/lib/alsa";
    unitConfig.ConditionVirtualization = "!systemd-nspawn";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.coreutils}/bin/mkdir -p /var/lib/alsa";
      ExecStop = "${pkgs.alsa-utils}/sbin/alsactl store --ignore";
    };
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

    settings.max-jobs = 4;
    # Enable content-addressed derivations and flaxes
    extraOptions = lib.mkForce ''
      experimental-features = nix-command flakes ca-derivations
      # keep-outputs = true
      # keep-derivations = true
      # use-xdg-base-directories = true
    '';
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    webInterface = false;
    drivers = [ pkgs.hplipWithPlugin ];
    browsing = true;
    openFirewall = true;
    # this gives access to anyone on the interface you might want to limit it see the official documentation
    allowFrom = [ "all" ];
    defaultShared = true; # If you want
  };

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

      brightnessctl () {
        for device in "$("${pkgs.brightnessctl}/bin/brightnessctl" --class="backlight" --list --machine | cut -f1 -d,)"; do
          "${pkgs.brightnessctl}/bin/brightnessctl" --exponent=4 "$@"
        done
      }

      trap "exit 0" TERM INT
      trap "brightnessctl --restore; kill %%" EXIT
      brightnessctl set "$min_brightness"
      sleep 2147483647 &
      wait
    '';
  in {
    enable = true;
    lockerCommand = "${config.security.wrapperDir}/slock";
    extraOptions = [ ''--notifier="${dim-screen}"'' ];
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
