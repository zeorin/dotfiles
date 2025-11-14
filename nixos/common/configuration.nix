# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

{
  lib,
  config,
  pkgs,
  self,
  nur,
  home-manager,
  sops-nix,
  devenv,
  nix-software-center,
  ...
}@moduleArgs:

{
  imports = (builtins.attrValues self.outputs.nixosModules) ++ [
    nur.modules.nixos.default
    home-manager.nixosModules.home-manager
    sops-nix.nixosModules.sops
    ./cachix.nix
    ./logiops.nix
  ];

  config = {
    nixpkgs = {
      config.allowUnfree = true;

      overlays = [
        # Add overlays your own flake exports (from overlays and pkgs dir):
        self.outputs.overlays.additions
        self.outputs.overlays.modifications
        self.outputs.overlays.unstable-packages

        devenv.overlays.default

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
                buildCommand = (oldAttrs.buildCommand or "") + ''
                  steamBin="$(readlink $out/bin/steam)"
                  rm $out/bin/steam
                  makeWrapper $steamBin $out/bin/steam --prefix LD_PRELOAD : ${preloadLibs}/\$PLATFORM/filter_SDL_DisableScreenSaver.so
                '';
              }
            )
          );
        })
      ];
    };

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
        (lib.filterAttrs (name: value: lib.isType "flake" value && name != "self")) moduleArgs
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
          # Devenv needs the users to be mentioned by name
          "zeorin"
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
      extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
      kernelModules = [ "v4l2loopback" ];
      extraModprobeConfig = ''
        options v4l2loopback devices=1 exclusive_caps=1 video_nr=10 card_label="OBS Camera"
      '';
      supportedFilesystems.ntfs = true;
    };

    services.udev.packages = with pkgs; [
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
      nix-software-center.packages.${system}.nix-software-center
      moreutils
      usbutils
      pciutils
      inetutils
      mtr
      config.boot.kernelPackages.v4l2loopback.bin
      v4l-utils
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
    environment.etc = (
      lib.mapAttrs' (name: value: {
        name = "nix/path/${name}";
        value.source = value.flake;
      }) config.nix.registry
    );

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

    i18n.extraLocaleSettings = {
      LC_ADDRESS = "en_ZA.UTF-8";
      LC_IDENTIFICATION = "en_ZA.UTF-8";
      LC_MEASUREMENT = "en_ZA.UTF-8";
      LC_MONETARY = "en_ZA.UTF-8";
      LC_NAME = "en_ZA.UTF-8";
      LC_NUMERIC = "en_ZA.UTF-8";
      LC_PAPER = "en_ZA.UTF-8";
      LC_TELEPHONE = "en_ZA.UTF-8";
      LC_TIME = "en_ZA.UTF-8";
    };

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
      keyMap =
        with config.services.xserver;
        pkgs.runCommand "xkb-console-keymap" { preferLocalBuild = true; } ''
          '${pkgs.buildPackages.ckbcomp}/bin/ckbcomp' \
            ${
              lib.optionalString (
                config.environment.sessionVariables ? XKB_CONFIG_ROOT
              ) "-I${config.environment.sessionVariables.XKB_CONFIG_ROOT}"
            } \
            -model '${xkb.model}' -layout '${xkb.layout}' \
            -option '${
              lib.replaceString "grp:win_space_toggle" "grp:alt_space_toggle" xkb.options
            }' -variant '${xkb.variant}' > "$out"
        '';
    };

    services.xserver = {
      enable = true;
      displayManager.gdm.enable = true;

      # Configure keymap in X11
      xkb = {
        dir = "${pkgs.big-bag-kbd-trix-xkb}/etc/X11/xkb";
        layout = "us,us";
        variant = ",dvp";
        options = "grp:win_space_toggle,shift:both_capslock,compose:menu";
      };
      exportConfiguration = true;
    };

    # Enable the GNOME Desktop Environment.
    services.xserver.desktopManager.gnome.enable = true;

    # Web browsers
    programs.firefox.enable = true;
    programs.chromium.enable = true;

    i18n.inputMethod = {
      enable = true;
      type = "ibus";
      ibus.engines = with pkgs.ibus-engines; [
        table
        table-others
      ];
    };

    programs.hyprland.enable = true;
    programs.hyprland.withUWSM = true;

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
            leftcontrol = "layer(layer1)";
            rightcontrol = "layer(layer1)";
            rightshift = "rightshift";
          };
          layer1 = {
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

    security.polkit.enable = true;

    # Enable sound.
    hardware.alsa.enablePersistence = true;
    security.rtkit.enable = true;
    services.pipewire = {
      audio.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    services.flatpak.enable = true;

    # Location-based stuff
    services.geoclue2.enable = true;
    services.geoclue2.geoProviderUrl = "https://beacondb.net/v1/geolocate";
    location.provider = "geoclue2";
    services.localtimed.enable = true;

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.zeorin = {
      isNormalUser = true;
      description = "Xandor Schiefer";
      shell = pkgs.fish;
      group = "zeorin";
      extraGroups = [
        "wheel"
        "networkmanager"
        "docker"
        "podman"
        "adbusers"
        "libvirtd"
        "video"
        "input"
        "i2c"
        "wireshark"
        "lp"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEOq1E9mycw3IYVGBpwEU9Oy9iirB8d5Xyu/+6CiL+mx openpgp:0x3CBFF97B"
      ];
    };
    users.groups.zeorin = { };
    home-manager = {
      extraSpecialArgs = (lib.filterAttrs (_: lib.isType "flake")) moduleArgs;
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "bak";
      users.zeorin = import ../../home-manager/home.nix;
    };

    sops = {
      defaultSopsFile = ../../secrets/secrets.yaml;
      secrets = {
        "mail.xandor.co.za/me@xandor.co.za" = {
          mode = "0400";
          owner = config.users.users.zeorin.name;
          group = config.users.users.zeorin.group;
        };
      };
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
          # Calibre wireless connection
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
          # Calibre wireless `BROADCAST_PORTS` for their ZeroConf wireless connection setup
          # https://github.com/kovidgoyal/calibre/blob/bdb77a370fa2f0ea2cde3b994bd7469322bfd065/src/calibre/devices/smart_device_app/driver.py#L251
          54982
          48123
          39001
          44044
          59678

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

    services.samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = "smbnix";
          "netbios name" = "smbnix";
          "security" = "user";
          # "use sendfile" = true;
          # "max protocol" = "smb2";
          # note: localhost is the ipv6 localhost ::1
          "hosts allow" = [
            "192.168.0."
            "127.0.0.1"
            "localhost"
          ];
          "hosts deny" = [ "0.0.0.0/0" ];
          "guest account" = "nobody";
          "map to guest" = "bad user";
        };
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
    hardware.graphics.enable = true;
    hardware.graphics.enable32Bit = true;

    virtualisation = {
      containers.enable = true;
      docker = {
        enable = true;
        autoPrune.enable = true;
        rootless = {
          enable = true;
          setSocketVariable = true;
        };
      };
      podman = {
        enable = true;
        autoPrune.enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };
      libvirtd.enable = true;
    };

    # Enable CUPS to print documents.
    services.printing.enable = true;

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

    security.pam.services.hyprlock = { };
    # security.pam.services.hibernate-on-multiple-failures = {
    #   name = "hibernate-on-multiple-failures";
    #   text = ''
    #     auth [success=1 new_authtok_reqd=ok ignore=ignore default=bad] pam_tally2.so onerr=succeed deny=3 even_deny_root unlock_time=30
    #     auth required pam_exec.so ${pkgs.systemd}/bin/systemctl hibernate
    #   '';
    # };
    # security.pam.services.login.text =
    #   lib.mkDefault (lib.mkBefore "auth include hibernate-on-multiple-failures");

    programs.seahorse.enable = true;
    programs.dconf.enable = true;
    programs.wireshark.enable = true;
    programs.adb.enable = true;
    programs.steam.enable = true;
    programs.gamemode.enable = true;

    environment.shells = [ pkgs.fish ];

    hardware.printers = {
      ensureDefaultPrinter = "MFC-2340DW";
      ensurePrinters = [
        {
          deviceUri = "ipps://brn94ddf82613d1.lan:443/ipp";
          location = "Xandor's Office";
          name = "MFC-2340DW";
          description = "Brother MFC-2340DW Inkjet Printer";
          model = "everywhere";
          ppdOptions = {
            PageSize = "A4"; # 215x345mm 3.5x5 3.5x5.Borderless 4x6 4x6.Borderless 5x7 5x7.Borderless 5x8 5x8.Borderless A3 A3.Borderless A4 A4.Borderless A5 A6 A6.Borderless Env10 EnvC5 EnvDL EnvMonarch Executive FanFoldGermanLegal Legal Letter Letter.Borderless Oficio Tabloid Tabloid.Borderless Custom.WIDTHxHEIGHT
            InputSlot = "Auto"; # Auto Main
            MediaType = "StationeryInkjet"; # Stationery PhotographicGlossy StationeryInkjet Com.brotherBp71
            cupsPrintQuality = "Draft"; # Draft Normal High
            ColorModel = "Gray"; # RGB Gray
            Duplex = "None"; # None DuplexNoTumble DuplexTumble
            OutputBin = "Faceup"; # FaceUp
          };
        }
      ];
    };

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
    system.stateVersion = "25.05"; # Did you read the comment?
  };
}
