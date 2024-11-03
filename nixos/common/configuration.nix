# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

{
  inputs,
  outputs,
  lib,
  config,
  options,
  pkgs,
  ...
}:
let
  round = x: if ((x / 2.0) >= 0.5) then (builtins.ceil x) else (builtins.floor x);
  dpiScale = x: x * (config.dpi / 96.0);
in

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./cachix.nix
    ./logiops.nix
  ];

  options = with lib; {
    dpi = mkOption {
      type = with types; int;
      default = 96;
      example = 192;
    };

    nixpkgs.allowUnfreePackages = mkOption {
      type = with types; (listOf (either str (functionTo bool)));
      default = [ ];
    };
  };

  config = {

    nixpkgs =
      let
        homePkgs =
          if ((options.home-manager or null) != null) then
            (outputs.homeConfigurations."zeorin@${config.networking.hostName}".config.nixpkgs or { })
          else
            { };
      in
      {
        overlays = [
          # Add overlays your own flake exports (from overlays and pkgs dir):
          outputs.overlays.additions
          outputs.overlays.modifications
          outputs.overlays.unstable-packages

          (_: prev: {
            slock = prev.slock.overrideAttrs (oldAttrs: {
              preBuild = "cp ${./slock-config.h} config.h";
              patches = (oldAttrs.patches or [ ]) ++ [ ./slock-patches.diff ];
              buildInputs = (oldAttrs.buildInputs or [ ]) ++ [ pkgs.imlib2 ];
            });
          })

          # Bugfix for steam client to not inhibit screensaver unless there's a game active
          # https://github.com/ValveSoftware/steam-for-linux/issues/5607
          # https://github.com/tejing1/nixos-config/blob/master/overlays/steam-fix-screensaver/default.nix
          (final: prev: {
            steam = (
              prev.steam.overrideAttrs (
                oldAttrs:
                let
                  inherit (builtins) concatStringsSep attrValues mapAttrs;
                  inherit (final)
                    stdenv
                    stdenv_32bit
                    runCommandWith
                    runCommandLocal
                    makeWrapper
                    ;
                  platforms = {
                    x86_64 = 64;
                    i686 = 32;
                  };
                  preloadLibFor =
                    bits:
                    assert bits == 64 || bits == 32;
                    runCommandWith {
                      stdenv = if bits == 64 then stdenv else stdenv_32bit;
                      runLocal = false;
                      name = "filter_SDL_DisableScreenSaver.${toString bits}bit.so";
                      derivationArgs = { };
                    } "gcc -shared -fPIC -ldl -m${toString bits} -o $out ${./filter_SDL_DisableScreenSaver.c}";
                  preloadLibs = runCommandLocal "filter_SDL_DisableScreenSaver" { } (
                    concatStringsSep "\n" (
                      attrValues (
                        mapAttrs (platform: bits: ''
                          mkdir -p $out/${platform}
                          ln -s ${preloadLibFor bits} $out/${platform}/filter_SDL_DisableScreenSaver.so
                        '') platforms
                      )
                    )
                  );
                in
                {
                  nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ makeWrapper ];
                  buildCommand =
                    (oldAttrs.buildCommand or "")
                    + ''
                      steamBin="$(readlink $out/bin/steam)"
                      rm $out/bin/steam
                      makeWrapper $steamBin $out/bin/steam --prefix LD_PRELOAD : ${preloadLibs}/\$PLATFORM/filter_SDL_DisableScreenSaver.so
                    '';
                }
              )
            );
          })
        ] ++ (homePkgs.overlays or [ ]);

        config = (homePkgs.config or { }) // {
          # https://github.com/NixOS/nixpkgs/issues/197325#issuecomment-1579420085
          allowUnfreePredicate =
            pkg:
            let
              names = lib.filter lib.isString config.nixpkgs.allowUnfreePackages;
              predicates = lib.filter lib.isFunction config.nixpkgs.allowUnfreePackages;
            in
            (builtins.elem (lib.getName pkg) names) || (lib.lists.any (p: p pkg) predicates);
        };

        allowUnfreePackages = [
          "steam"
          "steam-original"
          "steam-run"
        ] ++ (homePkgs.allowUnfreePackages or [ ]);
      };

    # Keep the system up-to-date automatically, also prune it from time to time.
    system.autoUpgrade.enable = true;

    nix = {
      daemonCPUSchedPolicy = "idle";
      daemonIOSchedClass = "idle";

      gc = {
        automatic = true;
        options = "--delete-older-than 14d";
      };

      optimise.automatic = true;

      # This will add each flake input as a registry
      # To make nix3 commands consistent with your flake
      registry = (lib.mapAttrs (_: flake: { inherit flake; })) (
        (lib.filterAttrs (_: lib.isType "flake")) inputs
      );
      nixPath = [ "/etc/nix/path" ];

      settings = {
        max-jobs = 4;
        experimental-features = lib.strings.concatStringsSep " " [
          "nix-command"
          "flakes"
        ];
        auto-optimise-store = true;
        trusted-users = [
          "root"
          "@wheel"
        ];
        # keep-outputs = true;
        # keep-derivations = true;
        # https://nixos.org/manual/nix/stable/command-ref/conf-file#conf-use-xdg-base-directories
        # use-xdg-base-directories = true;
      };
    };

    hardware.enableRedistributableFirmware = true;

    boot = {
      loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot = {
          enable = true;
          configurationLimit = 10;
          memtest86.enable = true;
          memtest86.sortKey = "zmemtest86";
        };
      };

      plymouth = {
        enable = true;
        theme = "breeze";
        extraConfig = ''
          DeviceScale=${toString (round (dpiScale 1))}
        '';
      };

      initrd.systemd.enable = true;

      # https://discourse.nixos.org/t/hibernate-doesnt-work-anymore/24673/14
      resumeDevice = lib.mkIf (config.swapDevices != [ ] && (builtins.head config.swapDevices) ? device) (
        lib.mkDefault (builtins.head config.swapDevices).device
      );

      kernelParams = [
        "quiet"
        "udev.log_level=3"
      ];
      kernelPackages = pkgs.unstable.linuxPackages_zen;
      extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
      kernelModules = [ "v4l2loopback" ];
      extraModprobeConfig = ''
        options v4l2loopback devices=1 exclusive_caps=1 video_nr=10 card_label="OBS Camera"
      '';
      supportedFilesystems.ntfs = true;

      binfmt.emulatedSystems = [ "aarch64-linux" ];
    };

    services.udev.packages = with pkgs; [
      alsa-utils
      brightnessctl
    ];
    services.udev.extraRules = ''
      # https://github.com/NixOS/nixpkgs/issues/226346#issuecomment-1892314545
      # SUBSYSTEM=="input", ACTION=="add", ATTR{name}!="keyd virtual*", RUN+="${pkgs.systemd}/bin/systemctl try-restart keyd.service"
    '';

    systemd.services = {
      v4l2loopback-test-card = {
        description = "OBS Camera test card, shown on timeout";
        after = [ "graphical.target" ];
        before = [ "shutdown.target" ];
        conflicts = [ "shutdown.target" ];
        path = [ pkgs.gst_all_1.gstreamer ];
        environment = {
          GST_DEBUG = "*:INFO";
          GST_PLUGIN_SYSTEM_PATH_1_0 = lib.strings.makeSearchPath "lib/gstreamer-1.0" (
            lib.attrsets.attrValues {
              inherit (pkgs.gst_all_1)
                gst-plugins-base
                gst-plugins-good
                gst-libav
                gst-vaapi
                ;
            }
          );
        };
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${config.boot.kernelPackages.v4l2loopback.bin}/bin/v4l2loopback-ctl set-timeout-image -t 3000 /dev/video10 ${./test-card.png}";
        };
      };
    };

    environment.systemPackages = with pkgs; [
      moreutils
      usbutils
      pciutils
      inetutils
      mtr
      config.boot.kernelPackages.v4l2loopback.bin
      alsa-utils
      virtiofsd

      # https://www.brendangregg.com/blog/2024-03-24/linux-crisis-tools.html
      procps
      util-linux
      sysstat
      iproute2
      numactl
      tcpdump
      config.boot.kernelPackages.turbostat
      config.boot.kernelPackages.perf
      bcc
      bpftrace
      trace-cmd
      ethtool
      tiptop
      cpuid
      msr-tools
      gdb
    ];

    powerManagement = {
      enable = true;
      cpuFreqGovernor = lib.mkDefault "performance";
    };
    services.tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        NMI_WATCHDOG = 0;
      };
    };

    systemd.sleep.extraConfig = "HibernateDelaySec=4h";
    services.logind.lidSwitch = "suspend-then-hibernate";
    services.logind.extraConfig = ''
      HandlePowerKey=hibernate
      HandleSuspendKey=suspend-then-hibernate
      IdleAction=suspend-then-hibernate
      IdleActionSec=1h
    '';

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    environment.etc =
      (lib.mapAttrs' (name: value: {
        name = "nix/path/${name}";
        value.source = value.flake;
      }) config.nix.registry)
      // {
        "systemd/system-sleep/post-hibernate-pkill-slock".source = pkgs.writeShellScript "post-hibernate-pkill-slock" ''
          if [ "$1-$SYSTEMD_SLEEP_ACTION" = "post-hibernate" ]; then
            ${pkgs.procps}/bin/pkill slock
          fi
        '';
      };

    networking = {
      # Easy network config
      networkmanager.enable = true;

      # Enable IPv6
      enableIPv6 = true;

      # The global useDHCP flag is deprecated, therefore explicitly set to false
      # here.  Per-interface useDHCP will be mandatory in the future, so this
      # generated config replicates the default behaviour.
      useDHCP = false;
    };
    systemd.network.wait-online.enable = false;

    # Select internationalisation properties.
    i18n.defaultLocale = "en_ZA.UTF-8";

    console = {
      font = lib.mkDefault "Lat2-Terminus16";
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
      keyMap = lib.mkDefault "dvorak-programmer";
      useXkbConfig = true;
    };

    environment.variables = {
      # Hardware acceleration in Firefox
      MOZ_X11_EGL = "1";
      # DPI
      GDK_SCALE = toString (round (dpiScale 1)); # GTK 3 doesn't accept fractional values; also scales fonts
      GDK_DPI_SCALE = toString (1.0 / (dpiScale 1.0)); # GTK 4 only; accepts fractional values, but ~GDK_SCALE~ scales UI & fonts, but so do the DPI settings, this scales just the fonts back down
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      QT_ENABLE_HIGHDPI_SCALING = "1";
      _JAVA_OPTIONS = "-Dsun.java2d.uiScale=${toString (dpiScale 1.0)}";
    };

    services.xserver = {
      enable = true;
      inherit (config) dpi;
      upscaleDefaultCursor = true;

      screenSection = ''
        # Option "DPI" "${toString config.dpi} x ${toString config.dpi}"
      '';

      serverFlagsSection = ''
        Option "StandbyTime"  "5"
        Option "SuspendTime"  "5"
        Option "OffTime"      "5"
        Option "BlankTime"    "5"
      '';

      # Configure keymap in X11
      xkb = {
        layout = "us,us";
        variant = "dvp,";
        options = "grp:alt_space_toggle,grp_led:scroll,shift:both_capslock_cancel,compose:menu,terminate:ctrl_alt_bksp";
      };

      displayManager = {
        # https://github.com/NixOS/nixpkgs/issues/174099#issuecomment-1201697954
        sessionCommands = ''
          ${lib.getBin pkgs.dbus}/bin/dbus-update-activation-environment --systemd --all
        '';
        # We need to create at least one session for auto login to work
        session = [
          {
            name = "xsession";
            manage = "desktop";
            start = ''
              ${pkgs.runtimeShell} $HOME/.xsession &
              waitPID=$!
            '';
          }
        ];
      };
    };

    services.displayManager.autoLogin.user = "zeorin";

    services.libinput.touchpad = {
      accelProfile = "adaptive";
      accelSpeed = "1";
      disableWhileTyping = true;
      naturalScrolling = true;
      additionalOptions = ''
        Option "PalmDetection" "True"
      '';
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
            leftcontrol = "overload(layer1, oneshot(layer1))";
            rightcontrol = "overload(layer1, oneshot(layer1))";
          };
          layer1 = {
            leftcontrol = "toggle(layer1)";
            rightcontrol = "toggle(layer1)";

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

            "1" = "f1";
            "2" = "f2";
            "3" = "f3";
            "4" = "f4";
            "5" = "f5";
            "6" = "f6";
            "7" = "f7";
            "8" = "f8";
            "9" = "f9";
            "0" = "f10";
            "-" = "f11";
            "=" = "f12";

            "~" = "escape";
            "\\" = "insert";
            backspace = "delete";

            m = "previoussong";
            "," = "playcd";
            "." = "nextsong";
            ";" = "volumeup";
            "/" = "volumedown";

            a = "brightnessup";
            z = "brightnessdown";
          };
          shift = {
            leftshift = "capslock";
            rightshift = "capslock";
          };
        };
        extraConfig = ''
          [layer1+shift]

          # Like wasd, but aligned with home row
          e = pageup
          s = home
          d = pagedown
          f = end

          # Same thing, but for right hand
          i = pageup
          j = home
          k = pagedown
          l = end

          # hjkl on the Dvorak layout
          c = pagedown
          v = pageup
          # j = home # already bound, luckily to the same key
          p = end

          m = rewind
          , = stopcd
          . = fastforward
          / = mute
        '';
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
    services.geoclue2.geoProviderUrl = "https://beacondb.net/v1/geolocate";
    location.provider = "geoclue2";
    services.localtimed.enable = true;

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.zeorin = {
      isNormalUser = true;
      shell = pkgs.fish;
      group = "zeorin";
      extraGroups = [
        "wheel"
        "networkmanager"
        "docker"
        "adbusers"
        "libvirtd"
        "video"
        "input"
        "i2c"
        "wireshark"
        "lp"
      ];
    };
    users.groups.zeorin = { };
    home-manager = {
      extraSpecialArgs = {
        inherit inputs outputs;
      };
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "bak";
      users.zeorin = import ../../home-manager/home.nix;
    };

    environment.pathsToLink = [
      "/share/xdg-desktop-portal"
      "/share/applications"
    ];

    networking = {
      iproute2.enable = true;
      firewall = {
        allowPing = true;
        allowedTCPPorts = [
          # Calibre wireless
          9090
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

    services.samba.enable = true;
    services.samba.securityType = "user";
    services.samba.openFirewall = true;
    services.samba.extraConfig = ''
      workgroup = WORKGROUP
      server string = smbnix
      netbios name = smbnix
      security = user
      #use sendfile = yes
      #max protocol = smb2
      # note: localhost is the ipv6 localhost ::1
      hosts allow = 192.168.0. 127.0.0.1 localhost
      hosts deny = 0.0.0.0/0
      guest account = nobody
      map to guest = bad user
    '';
    services.samba.shares = {
      public = {
        "path" = "/mnt/Shares/Public";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "username";
        "force group" = "groupname";
      };
      private = {
        "path" = "/mnt/Shares/Private";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "username";
        "force group" = "groupname";
      };
    };
    services.samba-wsdd.enable = true;
    services.samba-wsdd.openFirewall = true;

    services.tailscale = {
      enable = true;
      package = pkgs.tailscale;
      openFirewall = true;
      useRoutingFeatures = "client";
      extraUpFlags = [ "--accept-routes" ];
    };

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

    # Enable CUPS to print documents.
    services.printing.enable = true;
    services.printing.drivers = with pkgs; [
      gutenprint
      gutenprintBin
    ];

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

    services.avahi.enable = true;
    services.avahi.openFirewall = true;
    services.avahi.nssmdns4 = true;
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
    programs.xss-lock =
      let
        dim-screen = pkgs.writeShellScript "dim-screen" ''
          min_brightness=0

          trap "exit 0" TERM INT
          trap "${pkgs.brightnessctl}/bin/brightnessctl --device='*' --restore; kill %%" EXIT
          ${pkgs.brightnessctl}/bin/brightnessctl --device='*' --exponent=4 set "$min_brightness"
          sleep 2147483647 &
          wait
        '';
      in
      {
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
    programs.wireshark.enable = true;
    programs.adb.enable = true;
    programs.steam.enable = true;
    programs.gamemode.enable = true;

    environment.shells = [ pkgs.fish ];

    # Compatibility for binaries
    services.envfs.enable = true;
    programs.nix-ld = {
      enable = true;
      # https://github.com/Mic92/dotfiles/blob/main/nixos/modules/nix-ld.nix
      libraries = with pkgs; [
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
    };

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    system.stateVersion = "24.05"; # Did you read the comment?
  };
}
