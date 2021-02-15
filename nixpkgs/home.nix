{ pkgs, config, ... }:

let
  unstable = import <unstable> { config = { allowUnfree = true; }; };
in {
  programs.home-manager.enable = true;
  programs.man.generateCaches = true;

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "${config.home.sessionVariables.EDITOR}";
    LESS = "-FiRx4";
    PAGER = "less ${config.home.sessionVariables.LESS}";
  };

  programs.fish = {
    enable = true;
    shellAliases = {
      g = "git";
      e = "$EDITOR";
      m = "neomutt";
      h = "home-manager";
      o = "xdg-open";
      s = "systemctl";
      d = "docker";
      j = "journalctl -xe";
      l = "ls -la";
      cat = "${pkgs.bat}/bin/bat";
      grep = "grep --color=auto";
      ls = "ls --color=auto";
    };
    functions = {
      # Use Vi keys, and Emacs keys
      fish_user_key_bindings.body = ''
        # Execute this once per mode that emacs bindings should be used in
        fish_default_key_bindings -M insert
        # Then execute the vi-bindings so they take precedence when there's a conflict.
        # Without --no-erase fish_vi_key_bindings will default to
        # resetting all bindings.
        # The argument specifies the initial mode (insert, "default" or visual).
        fish_vi_key_bindings --no-erase insert
      '';
      man = {
        wraps = "man";
        description = "man with more formatting";
        body = ''
          set -x MANWIDTH ([ $COLUMNS -gt "80" ] && echo "80" || echo $COLUMNS)
          set -x LESS_TERMCAP_mb (printf '\e[5m')
          set -x LESS_TERMCAP_md (printf '\e[1;38;5;7m')
          set -x LESS_TERMCAP_me (printf '\e[0m')
          set -x LESS_TERMCAP_so (printf '\e[7;38;5;3m')
          set -x LESS_TERMCAP_se (printf '\e[27;39m')
          set -x LESS_TERMCAP_us (printf '\e[4;38;5;4m')
          set -x LESS_TERMCAP_ue (printf '\e[24;39m')
          command man $argv
        '';
      };
      ntfy_on_duration = {
        onEvent = "fish_prompt";
        body = ''
          if test $CMD_DURATION; and test $CMD_DURATION -gt (math "1000 * 10")
            set secs (math "$CMD_DURATION / 1000")
            ntfy -t "$history[1]" send "Returned $status, took $secs seconds"
          end
        '';
      };
    };
    interactiveShellInit = ''
      # Clear greeting message
      set fish_greeting

      # Tmux session chooser
      test -e ~/.tmux/session_chooser.fish && source ~/.tmux/session_chooser.fish

      # Vi cursor
      fish_vi_cursor
      set fish_cursor_default block
      set fish_cursor_insert line
      set fish_cursor_replace_one underscore
    '';
    promptInit = "${pkgs.starship}/bin/starship init fish | source";
  };

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    enableNixDirenvIntegration = true;
  };

  # Allow for bluetooth devices to interface with MPRIS
  systemd.user.services.mpris-proxy = {
    Unit.Description = "Mpris proxy";
    Unit.After = [ "network.target" "sound.target" ];
    Service.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
    Install.WantedBy = [ "default.target" ];
  };

  fonts.fontconfig.enable = true;

  # Overlays
  nixpkgs.overlays = [
    (import (builtins.fetchTarball { url = https://github.com/mozilla/nixpkgs-mozilla/archive/master.tar.gz; }))
    (self: super: { fish = unstable.fish; })
  ];

  home.packages = with pkgs; [
    libnotify file tree htop lsd gitAndTools.delta xsel xclip xdotool urlscan fpp
    lxqt.lxqt-policykit xdg-user-dirs
    wineWowPackages.staging (winetricks.override { wine = wineWowPackages.staging; }) protontricks
    capitaine-cursors arc-theme arc-icon-theme gtk_engines gtk-engine-murrine
    wget emacs vim nodejs neovim git tmux universal-ctags dex zip unzip numlockx ag xorg.xkill bc
    rofi dunst feh picom lxappearance arc-theme arc-icon-theme xorg.xcursorthemes
    (polybar.override { i3GapsSupport = true; mpdSupport = true; })
    protonvpn-gui protonvpn-cli
    thunderbird neomutt isync
    brightnessctl
    zathura calibre-py2 spotify
    ntfy
    gnome3.gnome-calculator
    youtube-dl
    gnucash xournalpp
    transmission-gtk mpv
    nextcloud-client weechat keepassxc pcmanfm lxmenu-data shared_mime_info
    spotify lutris vulkan-tools
    gimp inkscape krita libreoffice gnome3.file-roller
    x2x arandr unstable.barrier unstable.flameshot
    # TODO this is for the i3-fullscreen screensaver inhibition script, move to its own config later
    (python3.withPackages (python-packages: [ python-packages.i3ipc ]))
    direnv fish
    ethtool
    pavucontrol ncdu
    playerctl
    qutebrowser luakit surf
    latest.firefox-bin
    # need to figure out how to resolve collisions
    # latest.firefox-nightly-bin latest.firefox-beta-bin latest.firefox-esr-bin
    (chromium.override { enableVaapi = true; })
    google-chrome google-chrome-beta google-chrome-dev
    # unstable.tor-browser-bundle-bin
    unstable.manix nix-index nix-prefetch-git


    #########
    # FONTS #
    #########

    # Emoji
    twitter-color-emoji

    # Classic fonts
    eb-garamond
    #helvetica-neue-lt-std
    libre-bodoni
    libre-caslon
    libre-franklin
    etBook

    # Microsoft fonts
    corefonts
    #vistafonts

    # Metrically-compatible font replacements
    liberation_ttf
    liberation-sans-narrow
    meslo-lg

    # Libre fonts
    gentium gentium-book-basic
    crimson
    dejavu_fonts
    overpass
    raleway
    comic-neue comic-relief
    fira fira-mono
    roboto-mono
    inter
    lato
    libertine
    libertinus
    montserrat
    public-sans
    f5_6 route159 aileron eunomia seshat penna ferrum medio tenderness vegur
    source-code-pro
    xkcd-font
    gyre-fonts

    # Font collections
    google-fonts
    league-of-moveable-type
    # nerdfonts

    # Coding fonts
    # iosevka
    hack-font
    go-font
    hasklig
    fira-code
    inconsolata
    mononoki
    fantasque-sans-mono

    # Icon fonts
    font-awesome
    material-icons

    # Non-latin character sets
    junicode

    # Fallback fonts
    xorg.fontbhlucidatypewriter100dpi
    xorg.fontbhlucidatypewriter75dpi
    xorg.fontcursormisc
    symbola
    freefont_ttf
    unifont
    noto-fonts noto-fonts-extra noto-fonts-cjk
  ];

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "20.03";
}
# vim: set foldmethod=indent foldcolumn=4 shiftwidth=2 tabstop=2 expandtab:
