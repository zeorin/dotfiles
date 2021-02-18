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
      t = "tail -f";
      d = "docker";
      j = "journalctl -xe";
      ls = "ls --color=auto";
      l = "ls -lFh";     #size,show type,human readable
      la = "ls -lAFh";   #long list,show almost all,show type,human readable
      lr = "ls -tRFh";   #sorted by date,recursive,show type,human readable
      lt = "ls -ltFh";   #long list,sorted by date,show type,human readable
      ll = "ls -l";      #long list
      ldot = "ls -ld .*";
      lS = "ls -1FSsh";
      lart = "ls -1Fcart";
      lrt = "ls -1Fcrt";
      cat = "${pkgs.bat}/bin/bat";
      grep = "grep --color=auto";
      sgrep = "grep -R -n -H -C 5 --exclude-dir={.git,.svn,CVS}";
      dud = "du -d 1 -h";
      duf = "du -sh *";
      fd = "find . -type d -name";
      ff = "find . -type f -name";
      hgrep = "fc -El 0 | grep";
      sortnr = "sort -n -r";
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
      mkcd = {
        description = "Create a directory and change into it";
        body = "mkdir -p $argv[1] && cd $argv[1]";
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

      # Notify for long-running commands
      function ntfy_on_duration --on-event fish_prompt
        if test $CMD_DURATION; and test $CMD_DURATION -gt (math "1000 * 10")
          set secs (math "$CMD_DURATION / 1000")
          ${pkgs.ntfy}/bin/ntfy -t "$history[1]" send "Returned $status, took $secs seconds"
        end
      end
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

  programs.git = {
    enable = true;
    userName = "Xandor Schiefer";
    extraConfig = {
      user.useConfigOnly = true;
      core = {
        autocrlf = "input";
        eol = "lf";
        safecrlf = false;
        whitespace = "trailing-space,space-before-tab";
      };
      credential.helper = "cache";
      color.ui = true;
      push.default = "simple";
      advice = {
        statusHints = false;
        pushNonFastForward = false;
      };
      diff = {
        algorithm = "patience";
        renames = "copies";
        mnemonicprefix = true;
        tool = "nvimdiff";
        colormoved = "dimmed-zebra";
        colormovedws = "allow-indentation-change";
      };
      difftool.prompt = false;
      "difftool \"nvimdiff\"".cmd = "$VISUAL -d \"$LOCAL\" \"$REMOTE\"";
      merge = {
        stat = true;
        tool = "nvimdiff";
      };
      mergetool.prompt = false;
      "mergetool \"nvimdiff\"".cmd = "$VISUAL -d -c '4wincmd w | wincmd J'  \"$LOCAL\" \"$BASE\" \"$REMOTE\" \"$MERGED\"";
      branch.autosetupmerge = true;
      rerere = {
        enabled = true;
        autoUpdate = true;
      };
      log.abbrevCommit = true;
    };
    delta = {
      enable = true;
      options = {
        features = "side-by-side line-numbers decorations";
        white-space-error-style = "22 reverse";
        syntax-theme = "Solarized (dark)";
        decorations = {
          commit-decoration-style = "bold yellow box ul";
          file-style = "bold yellow ul";
          file-decoration-style = "none";
          hunk-header-decoration-style = "cyan box ul";
        };
      };
    };
    aliases = {
      a = "add";
      b = "branch";
      # Use commitizen if it’s installed, otherwise just use `git commit`
      c = "!f() { if command -v git-cz >/dev/null 2>&1; then git-cz \"$@\"; else git commit \"$@\"; fi; }; f";
      co = "checkout";
      d = "diff";
      p = "push";
      r = "rebase";
      s = "status";
      u = "!git unstage";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
      stash-unapply = "!git stash show -p | git apply -R";
      assume-unchanged = "!git ls-files -v | grep '^[[:lower:]]'";
      edit-dirty = "!git status --porcelain | sed s/^...// | xargs $EDITOR";
      tracked-ignores = "!git ls-files | git check-ignore --no-index --stdin";
      # https://www.erikschierboom.com/2020/02/17/cleaning-up-local-git-branches-deleted-on-a-remote/
      rm-gone = "!git for-each-ref --format '%(refname:short) %(upstream:track)' | awk '$2 == \"[gone]\" {print $1}' | xargs -r git branch -D";
      # https://stackoverflow.com/a/34467298
      l = "!git lg";
      lg = "!git lg1";
      lg1 = "!git lg1-specific --branches --decorate-refs-exclude=refs/remotes/*";
      lg2 = "!git lg2-specific --branches --decorate-refs-exclude=refs/remotes/*";
      lg3 = "!git lg3-specific --branches --decorate-refs-exclude=refs/remotes/*";
      lg-all = "!git lg1-all";
      lg1-all = "!git lg1-specific --all";
      lg2-all = "!git lg2-specific --all";
      lg3-all = "!git lg3-specific --all";
      lg-specific = "!git lg1-specific";
      lg1-specific = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'";
      lg2-specific = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'";
      lg3-specific = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset) %C(bold cyan)(committed: %cD)%C(reset) %C(auto)%d%C(reset)%n''          %C(white)%s%C(reset)%n''          %C(dim white)- %an <%ae> %C(reset) %C(dim white)(committer: %cn <%ce>)%C(reset)'";
      # https://docs.gitignore.io/use/command-line
      ignore = "!gi() { curl -sL https://www.gitignore.io/api/$@ 2>/dev/null ;}; gi";
    };
    ignores = [
      "*~"
      "*.swp"
      "*.swo"
      ".DS_Store"
      "tags"
      "Session.vim"
      "/.vim"
    ];
  };

  programs.tmux = {
    enable = true;
    baseIndex = 1;
    clock24 = true;
    disableConfirmationPrompt = true;
    keyMode = "vi";
    shortcut = "Space";
    terminal = "tmux-256color";

    extraConfig = ''
      # Vim-style selection
      bind-key -T copy-mode-vi v send-keys -X begin-selection

      # Show session selector (default to showing only unattached sessions)
      bind-key s choose-tree -s -f '#{?session_attached,0,1}'

      # Tmux window names
      set-option -g automatic-rename on
      set-option -g automatic-rename-format '#{pane_title}'

      # Terminal window names
      set-option -g set-titles on
      set-option -g set-titles-string '#{window_name}'

      # Clipboard integration
      set-option -g set-clipboard on

      # Mouse behaviour
      set-option -g mouse on

      set-option -g update-environment 'DISPLAY SSH_ASKPASS SSH_AUTH_SOCK SSH_AGENT_PID SSH_CONNECTION WINDOWID XAUTHORITY TERM'
    '';

    plugins = with pkgs.tmuxPlugins; [
      sensible
      pain-control
      sessionist
      prefix-highlight
      fpp
      {
        plugin = yank;
        extraConfig = ''
          set -g @override_copy_command '${pkgs.xsel}/bin/xsel'
          set -g @yank_action 'copy-pipe'
        '';
      }
      {
        plugin = open;
        extraConfig = ''
          set -g @open-S 'https://www.duckduckgo.com/'
        '';
      }
      {
        plugin = tmux-colors-solarized;
        extraConfig = ''
          set -g @colors-solarized 'dark'
        '';
      }
      {
        plugin = mkDerivation {
          pluginName = "fzf-url";
          version = "unstable-2021-02-20";
          rtpFilePath = "fzf-url.tmux";
          src = pkgs.fetchFromGitHub {
            owner = "wfxr";
            repo = "tmux-fzf-url";
            rev = "5b202610ae9dd788a4c07e18c07a2634854401cd";
            sha256 = "1plr4sablrh6f1ljrfm6arfxking8sgfa6n1gxx5bqysadf40nxg";
          };
          postInstall = ''
            sed -i -e 's|fzf-tmux|${pkgs.fzf}/bin/fzf-tmux|g' $target/fzf-url.sh
          '';
          dependencies = with pkgs; [ fzf ];
        };
      }
      {
        plugin = mkDerivation {
          pluginName = "extrakto";
          version = "unstable-2021-02-20";
          src = pkgs.fetchFromGitHub {
            owner = "laktak";
            repo = "extrakto";
            rev = "45201c7331f9c2964f278df11cf5aba8dc466155";
            sha256 = "0as8f4l9cqlq0haw95sagv7n83r3m817prjpn4yc5bh8x75adl25";
          };
          dependencies = with pkgs; [ python3 fzf ];
        };
        extraConfig = ''
          set-option -g @extrakto_fzf_tool '${pkgs.fzf}/bin/fzf'
          set-option -g @extrakto_clip_tool '${pkgs.xsel}/bin/xsel --input --clipboard' # works better for nvim
          set-option -g @extrakto_copy_key 'tab'
          set-option -g @extrakto_insert_key 'enter'
        '';
      }
      {
        plugin = mkDerivation {
          pluginName = "better-mouse-mode";
          rtpFilePath = "scroll_copy_mode.tmux";
          version = "unstable-2021-02-20";
          src = pkgs.fetchFromGitHub {
            owner = "NHDaly";
            repo = "tmux-better-mouse-mode";
            rev = "aa59077c635ab21b251bd8cb4dc24c415e64a58e";
            sha256 = "06346ih3hzwszhkj25g4xv5av7292s6sdbrdpx39p0n3kgf5mwww";
          };
        };
        extraConfig = ''
          set-option -g @scroll-without-changing-pane 'on'
          set-option -g @emulate-scroll-for-no-mouse-alternate-buffer 'on'
        '';
      }
    ];
  };

  xdg.configFile."bat/config".text = ''
    --theme="Solarized (dark)"
    --italic-text=always

    # Use "gitignore" highlighting for ".ignore" files
    --map-syntax='.ignore:Git Ignore'
  '';

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
    libnotify file tree htop lsd xsel xclip xdotool urlscan fpp
    lxqt.lxqt-policykit xdg-user-dirs
    wineWowPackages.staging (winetricks.override { wine = wineWowPackages.staging; }) protontricks
    capitaine-cursors arc-theme arc-icon-theme gtk_engines gtk-engine-murrine
    wget emacs vim nodejs neovim universal-ctags dex zip unzip numlockx ag xorg.xkill bc
    rofi dunst feh picom lxappearance arc-theme arc-icon-theme xorg.xcursorthemes
    (polybar.override { i3GapsSupport = true; mpdSupport = true; })
    protonvpn-gui protonvpn-cli
    thunderbird neomutt isync
    brightnessctl
    zathura calibre-py2 spotify
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
