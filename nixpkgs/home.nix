{ pkgs, config, lib, ... }:

let
  unstable = import <nixos-unstable> { config = config.nixpkgs.config; };

  myKey = "0x5E1C0971FE4F665A";

  doomEmacsSource = builtins.fetchGit "https://github.com/hlissner/doom-emacs";

  my-doom-emacs = let
    emacsPkg = with pkgs;
      (emacsPackagesFor emacs-gtk).emacsWithPackages (ps:
        with ps; [
          vterm
          (lsp-mode.overrideAttrs (oldAttrs: {
            LSP_USE_PLISTS = true;
            src = (let
              rev = builtins.readFile
                (let regex = ''package! lsp-mode :pin "\(.*\)"'';
                in runCommand "extract-lsp-mode-rev" { } ''
                  cat ${doomEmacsSource}/modules/tools/lsp/packages.el \
                    | grep '${regex}' -o \
                    | sed 's/${regex}/\1/' \
                    | tr -d "\n" \
                    > $out
                '');
            in builtins.fetchTarball
            "https://github.com/emacs-lsp/lsp-mode/archive/${rev}.tar.gz");
            patches = [
              (builtins.fetchurl
                "https://patch-diff.githubusercontent.com/raw/emacs-lsp/lsp-mode/pull/4092.diff")
            ];
          }))
        ]);
    pathDeps = with pkgs; [
      (aspellWithDicts (dicts: with dicts; [ en en-computers en-science ]))
      (hunspellWithDicts (with hunspellDicts; [ en_GB-large ]))
      (nuspellWithDicts (with hunspellDicts; [ en_GB-large ]))
      enchant
      languagetool
      ltex-ls
      texlive.combined.scheme-medium
      python3
      aspell
      binutils
      (ripgrep.override { withPCRE2 = true; })
      fd
      gnutls
      imagemagick
      zstd
      shfmt
      shellcheck
      sqlite
      editorconfig-core-c
      nodePackages.mermaid-cli
      pandoc
      gcc
      gdb
      lldb
      graphviz-nox
      wordnet
      beancount
      beancount-language-server
      fava
      haskell-language-server
      haskellPackages.hoogle
      haskellPackages.cabal-install
      haskellPackages.brittany
      haskellPackages.hlint
      html-tidy
      nodejs
      nodePackages.bash-language-server
      nodePackages.stylelint
      nodePackages.dockerfile-language-server-nodejs
      nodePackages.js-beautify
      nodePackages.typescript-language-server
      nodePackages.typescript
      (writeScriptBin "vscode-css-language-server" ''
        #!${nodejs}/bin/node
        require('${vscodium}/lib/vscode/resources/app/extensions/css-language-features/server/dist/node/cssServerMain.js')
      '')
      (writeScriptBin "vscode-html-language-server" ''
        #!${nodejs}/bin/node
        require('${vscodium}/lib/vscode/resources/app/extensions/html-language-features/server/dist/node/htmlServerMain.js')
      '')
      (writeScriptBin "vscode-json-language-server" ''
        #!${nodejs}/bin/node
        require('${vscodium}/lib/vscode/resources/app/extensions/json-language-features/server/dist/node/jsonServerMain.js')
      '')
      (writeScriptBin "vscode-markdown-language-server" ''
        #!${nodejs}/bin/node
        require('${vscodium}/lib/vscode/resources/app/extensions/markdown-language-features/server/dist/node/workerMain.js')
      '')
      nodePackages.yaml-language-server
      nodePackages.unified-language-server
      nodePackages.prettier
      jq
      nixfmt
      black
      isort
      pipenv
      python3Packages.pytest
      python3Packages.nose
      python3Packages.pyflakes
      python3Packages.python-lsp-server
      python3Packages.grip
      multimarkdown
      xclip
      xdotool
      xorg.xwininfo
      xorg.xprop
      watchman
    ];
  in emacsPkg // (pkgs.symlinkJoin {
    name = "my-doom-emacs";
    paths = [ emacsPkg ];
    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
    postBuild = ''
      wrapProgram $out/bin/emacs \
        --prefix PATH : ${lib.makeBinPath pathDeps} \
        --set LSP_USE_PLISTS true
      wrapProgram $out/bin/emacsclient \
        --prefix PATH : ${lib.makeBinPath pathDeps} \
        --set LSP_USE_PLISTS true
    '';
  });

  colors = {
    "nord0" = "#2E3440";
    "nord1" = "#3B4252";
    "nord2" = "#434C5E";
    "nord3" = "#4C566A";
    "nord4" = "#D8DEE9";
    "nord5" = "#E5E9F0";
    "nord6" = "#ECEFF4";
    "nord7" = "#8FBCBB";
    "nord8" = "#88C0D0";
    "nord9" = "#81A1C1";
    "nord10" = "#5E81AC";
    "nord11" = "#BF616A";
    "nord12" = "#D08770";
    "nord13" = "#EBCB8B";
    "nord14" = "#A3BE8C";
    "nord15" = "#B48EAD";
  };

  scripts = {
    isSshSession = pkgs.writeShellScript "is-ssh-session.sh" ''
      if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [ -n "$SSH_CONNECTION" ]; then
        exit 0
      else
        case $(ps -o comm= -p $PPID) in
          sshd|*/sshd) exit 0;;
        esac
      fi
      exit 1
    '';
    tmux = {
      addTmuxTerminfo = pkgs.writeShellScript "add-tmux-terminfo.sh" ''
        cat <<EOF|${pkgs.ncurses}/bin/tic -x -
        tmux|tmux terminal multiplexer,
          ritm=\E[23m, rmso=\E[27m, sitm=\E[3m, smso=\E[7m, Ms@,
          use=xterm+tmux, use=screen,

        tmux-256color|tmux with 256 colors,
          use=xterm+256setaf, use=tmux,
        EOF
      '';
      sessionChooser = pkgs.writeShellScript "tmux-session-chooser.sh" ''
        if [ -z "$TMUX" ] && \
          [ -z "$EMACS" ] && \
          [ -z "$VIM" ] && \
          [ -z "$INSIDE_EMACS" ] && \
          [ "$TERM_PROGRAM" != "vscode" ]; then

          # If this is a remote tty, allow the MOTD, banner, etc. to be seen first
          parent_process=$(${pkgs.procps}/bin/ps -o comm= -p "$PPID")
          if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [ -z "''${parent_process##*sshd}" ]; then
            echo -e '\e[7mPress any key to continue…\e[0m';
            saved_tty=$(stty -g </dev/tty)
            stty raw -echo
            dd if=/dev/tty bs=1 count=1 >/dev/null 2>&1
            stty "$saved_tty"
          fi

          tmux_unattached_sessions=$(${pkgs.tmux}/bin/tmux list-sessions -F '#{session_name} #{session_attached}' 2>/dev/null | grep ' 0$' | sed -e 's/ 0$//')

          if [ -z "$tmux_unattached_sessions" ]; then
            exec ${pkgs.tmux}/bin/tmux new-session
          else
            tmux_new_session=$(${pkgs.tmux}/bin/tmux new-session -dPF '#{session_name}')
            exec ${pkgs.tmux}/bin/tmux \
              attach -t "$tmux_new_session" \; \
              choose-tree -s -f '#{?session_attached,0,1}' \
                "switch-client -t '%%'; kill-session -t '$tmux_new_session'"
          fi
        fi
      '';
      sessionChooserFish = pkgs.writeTextFile {
        name = "tmux-session-chooser.fish";
        text = ''
          #!${pkgs.fish}/bin/fish

          if [ -z "$TMUX" ] && \
            [ -z "$EMACS" ] && \
            [ -z "$VIM" ] && \
            [ -z "$INSIDE_EMACS" ] && \
            [ "$TERM_PROGRAM" != "vscode" ]

            # If this is a remote tty, allow the MOTD, banner, etc. to be seen first
            set parent_process (${pkgs.procps}/bin/ps -o comm= -p (${pkgs.procps}/bin/ps -o ppid= -p $fish_pid | string trim))
            if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || string match -q -- sshd $parent_process
              echo -ne '\e[7mPress any key to continue…\e[0m';
              set saved_tty (stty -g </dev/tty)
              stty raw -echo
              dd if=/dev/tty bs=1 count=1 >/dev/null 2>&1
              stty "$saved_tty"
            end

            set tmux_unattached_sessions (${pkgs.tmux}/bin/tmux list-sessions -F '#{session_name} #{session_attached}' 2>/dev/null | grep ' 0$' | sed -e 's/ 0$//')

            if [ -z "$tmux_unattached_sessions" ]
              exec ${pkgs.tmux}/bin/tmux new-session
            else
              set tmux_new_session (${pkgs.tmux}/bin/tmux new-session -dPF '#{session_name}')
              exec ${pkgs.tmux}/bin/tmux \
                attach -t "$tmux_new_session" \; \
                choose-tree -s -f '#{?session_attached,0,1}' \
                  "switch-client -t '%%'; kill-session -t '$tmux_new_session'"
            end
          end
        '';
        executable = true;
      };
    };
  };
  terminal-emulator = "${config.programs.kitty.package}/bin/kitty";

in {
  nixpkgs.overlays = [
    (import (builtins.fetchTarball
      "https://github.com/mozilla/nixpkgs-mozilla/archive/master.tar.gz"))
  ];

  imports = [
    "${
      fetchTarball
      "https://github.com/msteen/nixos-vscode-server/tarball/master"
    }/modules/vscode-server/home.nix"
  ];

  home = {
    username = "zeorin";
    homeDirectory = "/home/${config.home.username}";
    keyboard = {
      layout = "us,us";
      variant = "dvp,";
      options = [
        "grp:alt_space_toggle"
        "grp_led:scroll"
        "shift:both_capslock"
        "compose:menu"
        "terminate:ctrl_alt_bksp"
      ];
    };
    sessionPath = [ "${config.xdg.configHome}/doom-emacs/bin" ];
    sessionVariables = with config.xdg;
      let
        EDITOR = pkgs.writeShellScript "EDITOR.sh" ''
          if [ -n "$INSIDE_EMACS" ]; then
            ${my-doom-emacs}/bin/emacsclient --quiet "$@"
          else
            ${my-doom-emacs}/bin/emacsclient --tty --alternate-editor="" --quiet "$@"
          fi
        '';
        VISUAL = pkgs.writeShellScript "VISUAL.sh" ''
          if [ -n "$INSIDE_EMACS" ]; then
            ${my-doom-emacs}/bin/emacsclient --quiet "$@"
          elif [ "$SSH_TTY$DISPLAY" = "''${DISPLAY#*:[1-9][0-9]}" ]; then
            # If we're not connected via SSH and the DISPLAY is less than 10
            ${my-doom-emacs}/bin/emacsclient --create-frame --alternate-editor="" --quiet "$@"
          else
            ${EDITOR} "$@"
          fi
        '';
      in rec {
        inherit EDITOR VISUAL;
        # Non-standard env var, found in https://github.com/facebook/react/pull/22649
        EDITOR_URL = "editor://open?file={path}&line={line}";
        # Non-standard env var, found in https://github.com/yyx990803/launch-editor
        LAUNCH_EDITOR = pkgs.writeShellScript "launch-editor.sh" ''
          filename=$1
          line=$2
          column=$3

          ${my-doom-emacs}/bin/emacsclient +$line:$column "$filename"
        '';
        SUDO_EDITOR = VISUAL;
        LESS = "-FiRx4";
        PAGER = "less ${LESS}";
        # Non-standard env var, found in https://github.com/i3/i3/blob/next/i3-sensible-terminal
        TERMINAL = "${terminal-emulator}";

        # Help some tools actually adhere to XDG Base Dirs
        CURL_HOME = "${configHome}/curl";
        INPUTRC = "${configHome}/readline/inputrc";
        NPM_CONFIG_USERCONFIG = "${configHome}/npm/npmrc";
        WGETRC = "${configHome}/wget/wgetrc";
        LESSHISTFILE = "${cacheHome}/less/history";
        PSQL_HISTORY = "${cacheHome}/pg/psql_history";
        XCOMPOSECACHE = "${cacheHome}/X11/xcompose";
        GOPATH = "${dataHome}/go";
        MYSQL_HISTFILE = "${dataHome}/mysql_history";
        NODE_REPL_HISTORY = "${dataHome}/node_repl_history";
        STACK_ROOT = "${dataHome}/stack";
        WINEPREFIX = "${dataHome}/wineprefixes/default";
        DOOMDIR = "${configHome}/doom";
        DOOMLOCALDIR = "${dataHome}/doom";

        # Suppress direnv's verbose output
        # https://github.com/direnv/direnv/issues/68#issuecomment-42525172
        DIRENV_LOG_FORMAT = "";

        # TODO: figure out how to fall back to regular entry if no GPG smartcard
        # is found / no key is unlocked
        # Use `pass` to input SSH passwords
        SSH_ASKPASS_REQUIRE = "force";
        SSH_ASKPASS = pkgs.writeShellScript "ssh-askpass-pass.sh" ''
          key="$(echo "$1" | sed -e "s/^.*\/\(.*[^']\)'\{0,1\}:.*$/\1/")"
          ${pkgs.pass}/bin/pass "ssh/$key" | head -n1
        '';
        # Use `pass` to input the sudo password
        SUDO_ASKPASS = pkgs.writeShellScript "sudo-askpass-pass.sh" ''
          hostname="$(${pkgs.hostname}/bin/hostname)"
          ${pkgs.pass}/bin/pass "$hostname/$USER" | head -n1
        '';

        DASHT_DOCSETS_DIR = "${config.xdg.dataFile.docsets.source}";
      };
    activation = with config.xdg; {
      createXdgCacheAndDataDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # Cache dirs
        for dir in less pg X11; do
          $DRY_RUN_CMD mkdir --parents $VERBOSE_ARG \
            ${cacheHome}/$dir
        done

        # Data dirs
        for dir in bash go pass stack wineprefixes picom; do
          $DRY_RUN_CMD mkdir --parents $VERBOSE_ARG \
            ${dataHome}/$dir
        done
        $DRY_RUN_CMD mkdir --parents $VERBOSE_ARG \
          --mode=700 ${dataHome}/gnupg

        # Flameshot dir
        $DRY_RUN_CMD mkdir --parents $VERBOSE_ARG \
          ${config.home.homeDirectory}/Screenshots
      '';
    };
    shellAliases = with pkgs; {
      g = "git";
      e = "edit.sh";
      m = "neomutt";
      h = "home-manager";
      o = "xdg-open";
      s = "systemctl";
      t = "tail -f";
      d = "docker";
      j = "journalctl -xe";
      ls = "${lsd}/bin/lsd";
      l = "ls -lFh"; # size,show type,human readable
      la = "ls -lAFh"; # long list,show almost all,show type,human readable
      lr = "ls -tRFh"; # sorted by date,recursive,show type,human readable
      lt = "ls -ltFh"; # long list,sorted by date,show type,human readable
      ll = "ls -l"; # long list
      ldot = "ls -ld .*";
      lS = "ls -1FSsh";
      lart = "ls -1Fcart";
      lrt = "ls -1Fcrt";
      tree = "${lsd}/bin/lsd --tree";
      cat = "${bat}/bin/bat";
      grep = "grep --color=auto";
      sgrep = "grep -R -n -H -C 5 --exclude-dir={.git,.svn,CVS}";
      hgrep = "fc -El 0 | grep";
      dud = "du -d 1 -h";
      duf = "du -sh *";
      sortnr = "sort -n -r";
      sudo = "sudo --askpass";
    };
  };

  programs = {
    home-manager.enable = true;
    bash.enable = true;
    browserpass = {
      enable = true;
      browsers = [ "firefox" "chromium" "chrome" ];
    };
    dircolors = {
      enable = true;
      extraConfig = builtins.readFile "${
          builtins.fetchGit {
            url = "https://github.com/nordtheme/dircolors";
            ref = "refs/tags/v0.2.0";
          }
        }/src/dir_colors";
    };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      config = {
        strict_env = true;
        warn_timeout = "30s";
      };
    };
    firefox = {
      enable = true;
      package = pkgs.latest.firefox-bin.override {
        cfg.enableBrowserpass = true;
        cfg.enableTridactylNative = true;
      };
      extensions = with pkgs.nur.repos.rycee.firefox-addons;
        [
          a11ycss
          auto-tab-discard
          browserpass
          canvasblocker
          clearurls
          cookies-txt
          darkreader
          fediact
          mailvelope
          metamask
          octolinker
          octotree
          org-capture
          privacy-badger
          react-devtools
          reddit-enhancement-suite
          reduxdevtools
          refined-github
          tab-session-manager
          terms-of-service-didnt-read
          tree-style-tab
          tridactyl
          ublock-origin
          wappalyzer
          wayback-machine
        ] ++ [
          pkgs.nur.repos.ethancedwards8.firefox-addons.enhancer-for-youtube
          pkgs.nur.repos.pborzenkov.firefox-addons.wallabagger
        ] ++ [
          (buildFirefoxXpiAddon rec {
            pname = "better_tweetdeck";
            version = "4.7.2";
            addonId = "BetterTweetDeckDev@erambert.me";
            url =
              "https://addons.mozilla.org/firefox/downloads/file/3891208/better_tweetdeck-${version}-fx.xpi";
            sha256 = "1ckp7n2qjhwnzzdrsw50ahrcdsszcsgr6gsxamhf9p2dpfxhxiny";
            meta = with lib; {
              homepage = "https://better.tw/";
              description =
                "Improve your experience on TweetDeck web with emojis, thumbnails, and a lot of customization options to make TweetDeck even better for you.";
              licence = licences.mit;
              platforms = platforms.all;
            };
          })
          (buildFirefoxXpiAddon rec {
            pname = "cors-everywhere";
            version = "18.11.13.2043";
            addonId = "cors-everywhere@spenibus";
            url =
              "https://addons.mozilla.org/firefox/downloads/file/1148493/cors_everywhere-${version}-fx.xpi";
            sha256 = "0kw89yjsw0dggdk8h238h7fzjpi7wm58gnnad8vpnax63xp90chj";
            meta = with lib; {
              homepage =
                "https://github.com/spenibus/cors-everywhere-firefox-addon";
              description =
                "Bypass CORS restrictions by altering http responses.";
              licence = licences.mit;
              platforms = platforms.all;
            };
          })
          (buildFirefoxXpiAddon rec {
            pname = "redirect-amp-to-html";
            version = "2.1.0";
            addonId = "{569456be-2850-4f7e-b669-71e55140ee0a}";
            url =
              "https://addons.mozilla.org/firefox/downloads/file/3546077/redirect_amp_to_html-${version}-an+fx.xpi";
            sha256 = "142plr60v7w4niwm5kpmaymmaqn319rwfwakh3ad6c1cg0r40bkn";
            meta = with lib; {
              homepage =
                "https://www.daniel.priv.no/web-extensions/amp2html.html";
              description =
                "Automatically redirects AMP pages to the regular web page variant.";
              licence = with licences; [ mit x11 ];
              platforms = platforms.all;
            };
          })
        ];
      profiles = let
        commonSettings = {
          "browser.startup.page" = 3; # resume previous session
          "browser.startup.homepage" = "about:blank";
          "browser.newtabpage.enabled" = false;
          "browser.newtab.preload" = false;
          "browser.newtab.url" = "about:blank";
          "browser.startup.homepage_override.mstone" =
            "ignore"; # hide welcome & what's new notices
          "browser.messaging-system.whatsNewPanel.enabled" =
            false; # hide what's new
          "browser.menu.showViewImageInfo" = true; # restore "view image info"
          "browser.ctrlTab.recentlyUsedOrder" = false; # use chronological order
          "browser.display.show_image_placeholders" = false;
          "browser.tabs.loadBookmarksInTabs" =
            true; # open bookmarks in a new tab
          "browser.urlbar.decodeURLsOnCopy" = true;
          "editor.truncate_user_pastes" =
            false; # don't truncate pasted passwords
          "media.videocontrols.picture-in-picture.video-toggle.has-used" =
            true; # smaller picture-in-picture icon
          "accessibility.typeaheadfind" = true; # enable "Find As You Type"
          "layout.spellcheckDefault" = 2; # multi-line & single-line
          # we use an external password manager
          "signon.rememberSignons" = false;
          "privacy.clearOnShutdown.passwords" = true;
          # dropdown options in the URL bar
          "browser.urlbar.suggest.bookmarks" = true;
          "browser.urlbar.suggest.engines" = false;
          "browser.urlbar.suggest.history" = true;
          "browser.urlbar.suggest.openpage" = true;
          "browser.urlbar.suggest.searches" = true;
          "browser.urlbar.suggest.topsites" =
            false; # disable dropdown suggestions with empty query
          # Smooth scroll
          "general.smoothScroll" = true;
          "general.smoothScroll.currentVelocityWeighting" = "0.1";
          "general.smoothScroll.mouseWheel.durationMaxMS" = 250;
          "general.smoothScroll.mouseWheel.durationMinMS" = 125;
          "general.smoothScroll.stopDecelerationWeighting" = "0.7";
          "mousewheel.min_line_scroll_amount" = 25;
          "apz.overscroll.enabled" = true; # elastic overscroll
          # Disable annoying warnings
          "browser.tabs.warnOnClose" = false;
          "browser.tabs.warnOnCloseOtherTabs" = false;
          "browser.tabs.warnOnOpen" = false;
          "browser.aboutConfig.showWarning" = false;
          # Hide bookmarks toolbar
          "browser.toolbars.bookmarks.visibility" = "never";
          # Allow all fontconfig substitutions
          "gfx.font_rendering.fontconfig.max_generic_substitutions" = 127;
          # Use system emoji
          "font.name-list.emoji" = "emoji";
          # HTTPS-only
          "dom.security.https_only_mode" = true;
          "dom.security.https_only_mode_ever_enabled" = true;
        };
        noNoiseSuppression = {
          "media.getusermedia.aec_enabled" = false;
          "media.getusermedia.agc_enabled" = false;
          "media.getusermedia.noise_enabled" = false;
          "media.getusermedia.hpf_enabled" = false;
        };
        performanceSettings = {
          "gfx.webrender.all" = true; # Use webrender everywhere
          # "gfx.webrender.software" = true; # If the hardware doesn't support it, use software webrendering
          "dom.image-lazy-loading.enabled" = true;
          # Restore tabs only on demand
          "browser.sessionstore.restore_on_demand" = true;
          "browser.sessionstore.restore_pinned_tabs_on_demand" = true;
          "browser.sessionstore.restore_tabs_lazily" = true;
          # Disable preSkeletonUI on startup
          "browser.startup.preXulSkeletonUI" = false;
          # Process count (more is faster, but uses more memory)
          # "dom.ipc.processCount" = 8; # default
          # "dom.ipc.processCount" = 16;
          "dom.ipc.processCount" = -1; # as many as FF wants
          "network.http.max-persistent-connections-per-server" = 10; # default 6
        };
        enableUserChrome = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "browser.autofocus" = false;
        };
        saneNewTab = {
          # Don't open links in new tabs, except when it makes sense
          "browser.link.open_newwindow" = 1; # force new window into same tab
          "browser.link.open_newwindow.restriction" =
            2; # except for script windows with features
          "browser.link.open_newwindow.override.external" =
            3; # open external links in a new tab in last active window
          "browser.newtab.url" = "about:blank";
        };
      in {
        personal = {
          id = 0;
          isDefault = true;
          settings = commonSettings // noNoiseSuppression // performanceSettings
            // enableUserChrome // saneNewTab;
          extraConfig = ''
            // http://kb.mozillazine.org/About:config_entries

            // Given that we're managing updates declaratively, we don't want to auto-update
            user_pref("extensions.update.enabled", false);
            user_pref("app.update.enabled", false);
          '';
          userChrome = let
            firefox-csshacks = builtins.fetchGit
              "https://github.com/MrOtherGuy/firefox-csshacks";
          in ''
            @import url('${firefox-csshacks}/chrome/hide_tabs_toolbar.css');
            @import url('${firefox-csshacks}/chrome/window_control_placeholder_support.css');
            @import url('${firefox-csshacks}/chrome/autohide_toolbox.css');

            /* autohide_toolbox.css: If tabs toolbar is hidden with hide_tabs_toolbar.css */
            #titlebar { margin-bottom: -9px; }
          '';
        };
        blank = { id = 1; };
        nightly = {
          id = 2;
          settings = commonSettings // noNoiseSuppression;
          extraConfig = ''
            // http://kb.mozillazine.org/About:config_entries

            // Given that we're managing updates declaratively, we don't want to auto-update
            user_pref("extensions.update.enabled", false);
            user_pref("app.update.enabled", false);
          '';
        };
        beta = {
          id = 3;
          settings = commonSettings // noNoiseSuppression;
          extraConfig = ''
            // http://kb.mozillazine.org/About:config_entries

            // Given that we're managing updates declaratively, we don't want to auto-update
            user_pref("extensions.update.enabled", false);
            user_pref("app.update.enabled", false);
          '';
        };
        esr = {
          id = 4;
          settings = commonSettings // noNoiseSuppression;
          extraConfig = ''
            // http://kb.mozillazine.org/About:config_entries

            // Given that we're managing updates declaratively, we don't want to auto-update
            user_pref("extensions.update.enabled", false);
            user_pref("app.update.enabled", false);
          '';
        };
      };
    };
    fish = {
      enable = true;
      # Functions defined here are lazy-loaded, so any functions that react to
      # signals shouldn’t be defined here.
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
            set --export MANWIDTH ([ "$COLUMNS" -gt "80" ] && echo "80" || echo "$COLUMNS")
            set --export LESS_TERMCAP_mb (printf '\e[5m')
            set --export LESS_TERMCAP_md (printf '\e[1;38;5;7m')
            set --export LESS_TERMCAP_me (printf '\e[0m')
            set --export LESS_TERMCAP_so (printf '\e[7;38;5;3m')
            set --export LESS_TERMCAP_se (printf '\e[27;39m')
            set --export LESS_TERMCAP_us (printf '\e[4;38;5;4m')
            set --export LESS_TERMCAP_ue (printf '\e[24;39m')
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
        source ${scripts.tmux.sessionChooserFish}

        # Vi cursor
        fish_vi_cursor
        set fish_cursor_default block
        set fish_cursor_insert line
        set fish_cursor_replace_one underscore
        set fish_vi_force_cursor true

        # Notify for long-running commands
        function ntfy_on_duration --on-event fish_prompt
          if test "$CMD_DURATION" -gt (math "1000 * 10")
            set secs (math "$CMD_DURATION / 1000")
            ${pkgs.ntfy}/bin/ntfy -t "$history[1]" send "Returned $status, took $secs seconds"
          end
        end

        # Determine whether to use side-by-side mode for delta
        function delta_sidebyside --on-signal WINCH
          if test "$COLUMNS" -ge 170; and ! contains side-by-side "$DELTA_FEATURES"
            set --global --export --append DELTA_FEATURES side-by-side
          else if test "$COLUMNS" -lt 170; and contains side-by-side "$DELTA_FEATURES"
            set --erase DELTA_FEATURES[(contains --index side-by-side "$DELTA_FEATURES")]
          end
        end
        delta_sidebyside

        # https://github.com/akermu/emacs-libvterm
        if test -n "$INSIDE_EMACS"
          source ${my-doom-emacs.emacs.pkgs.vterm}/share/emacs/site-lisp/elpa/vterm-${my-doom-emacs.emacs.pkgs.vterm.version}/etc/emacs-vterm.fish
        end
      '';
    };
    fzf = {
      enable = true;
      defaultCommand =
        "${pkgs.fd}/bin/fd --type file --strip-cwd-prefix --glob";
      fileWidgetCommand =
        "${pkgs.fd}/bin/fd --type empty --type file --strip-cwd-prefix --hidden --follow --glob";
      changeDirWidgetCommand =
        "${pkgs.fd}/bin/fd --type empty --type directory --strip-cwd-prefix --hidden --follow --glob";
    };
    git = {
      enable = true;
      userName = "Xandor Schiefer";
      extraConfig = {
        user.useConfigOnly = true;
        github.user = "zeorin";
        gitlab.user = "zeorin";
        bitbucket.user = "zeorin";
        gitlab.pixeltheory.user = "zeorin";
        core = {
          autocrlf = "input";
          eol = "lf";
          safecrlf = false;
          whitespace = "trailing-space,space-before-tab";
        };
        init.defaultBranch = "main";
        credential.helper = "${pkgs.pass-git-helper}/bin/pass-git-helper";
        color.ui = true;
        push.default = "simple";
        fetch.prune = true;
        pull.rebase = true;
        rebase.autoStash = true;
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
        "difftool \"nvimdiff\"".cmd = ''$VISUAL -d "$LOCAL" "$REMOTE"'';
        merge = {
          stat = true;
          tool = "nvimdiff";
          autoStash = true;
        };
        mergetool.prompt = false;
        "mergetool \"nvimdiff\"".cmd = ''
          $VISUAL -d -c '4wincmd w | wincmd J'  "$LOCAL" "$BASE" "$REMOTE" "$MERGED"'';
        branch.autosetupmerge = true;
        rerere = {
          enabled = true;
          autoUpdate = true;
        };
        log.abbrevCommit = true;
      };
      includes = [
        {
          path = "~/Code/WyzeTalk/.gitconfig";
          condition = "gitdir:~/Code/WyzeTalk/";
        }
        {
          path = "~/Code/NectaTech/.gitconfig";
          condition = "gitdir:~/Code/NectaTech/";
        }
      ];
      signing = {
        key = myKey;
        signByDefault = true;
      };
      delta = {
        enable = true;
        options = {
          features = "line-numbers decorations";
          white-space-error-style = "22 reverse";
          syntax-theme = "Nord";
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
        c = ''
          !f() { if command -v git-cz >/dev/null 2>&1; then git-cz "$@"; else git commit "$@"; fi; }; f'';
        co = "checkout";
        d = "diff";
        p = "push";
        r = "rebase";
        s = "status";
        u = "unstage";
        unstage = "reset HEAD --";
        last = "log -1 HEAD";
        stash-unapply = "!git stash show -p | git apply -R";
        assume = "update-index --assume-unchanged";
        unassume = "update-index --no-assume-unchanged";
        assumed =
          "!git ls-files -v | ${pkgs.gnugrep}/bin/grep '^h' | cut -c 3-";
        assume-all =
          "!git status | ${pkgs.gawk}/bin/awk {'print $2'} | ${pkgs.findutils}/bin/xargs -r git assume";
        unassume-all =
          "!git assumed | ${pkgs.findutils}/bin/xargs -r git unassume";
        edit-dirty =
          "!git status --porcelain | ${pkgs.gnused}/bin/sed s/^...// | ${pkgs.findutils}/bin/xargs -r $VISUAL";
        tracked-ignores = "!git ls-files | git check-ignore --no-index --stdin";
        # https://www.erikschierboom.com/2020/02/17/cleaning-up-local-git-branches-deleted-on-a-remote/
        branch-purge =
          "!git for-each-ref --format='%(if:equals=[gone])%(upstream:track)%(then)%(refname:short)%(end)' refs/heads | ${pkgs.findutils}/bin/xargs -r git branch -d";
        # https://stackoverflow.com/a/34467298
        l = "lg";
        lg = "lg1";
        lg1 = "lg1-specific --branches --decorate-refs-exclude=refs/remotes/*";
        lg2 = "lg2-specific --branches --decorate-refs-exclude=refs/remotes/*";
        lg3 = "lg3-specific --branches --decorate-refs-exclude=refs/remotes/*";
        lg-all = "lg1-all";
        lg1-all = "lg1-specific --all";
        lg2-all = "lg2-specific --all";
        lg3-all = "lg3-specific --all";
        lg-specific = "lg1-specific";
        lg1-specific =
          "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'";
        lg2-specific =
          "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'";
        lg3-specific =
          "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset) %C(bold cyan)(committed: %cD)%C(reset) %C(auto)%d%C(reset)%n''          %C(white)%s%C(reset)%n''          %C(dim white)- %an <%ae> %C(reset) %C(dim white)(committer: %cn <%ce>)%C(reset)'";
        # https://docs.gitignore.io/use/command-line
        ignore = ''
          !f() { ${pkgs.curl}/bin/curl -sL "https://www.gitignore.io/api/$@" 2>/dev/null; }; f'';
      };
      ignores =
        [ "*~" "*.swp" "*.swo" ".DS_Store" "tags" "Session.vim" "/.vim" ];
    };
    gpg = {
      enable = true;
      homedir = "${config.xdg.dataHome}/gnupg";
      settings = {
        # https://github.com/drduh/config/blob/master/gpg.conf
        # https://www.gnupg.org/documentation/manuals/gnupg/GPG-Configuration-Options.html
        # https://www.gnupg.org/documentation/manuals/gnupg/GPG-Esoteric-Options.html
        # Use AES256, 192, or 128 as cipher
        personal-cipher-preferences = "AES256 AES192 AES";
        # Use SHA512, 384, or 256 as digest
        personal-digest-preferences = "SHA512 SHA384 SHA256";
        # Use ZLIB, BZIP2, ZIP, or no compression
        personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
        # Default preferences for new keys
        default-preference-list =
          "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
        # SHA512 as digest to sign keys
        cert-digest-algo = "SHA512";
        # SHA512 as digest for symmetric ops
        s2k-digest-algo = "SHA512";
        # AES256 as cipher for symmetric ops
        s2k-cipher-algo = "AES256";
        # UTF-8 support for compatibility
        charset = "utf-8";
        # Show Unix timestamps
        fixed-list-mode = true;
        # No comments in signature
        no-comments = true;
        # No version in output
        no-emit-version = true;
        # Disable banner
        no-greeting = true;
        # Long hexidecimal key format
        keyid-format = "0xlong";
        list-options = lib.strings.concatStringsSep "," [
          # Display UID validity
          "show-uid-validity"
          # Show expired keys
          "show-unusable-subkeys"
        ];
        verify-options = lib.strings.concatStringsSep "," [
          # Display UID validity
          "show-uid-validity"
        ];
        # Display all keys and their fingerprints
        with-fingerprint = true;
        # Display key origins and updates
        with-key-origin = true;
        # Cross-certify subkeys are present and valid
        require-cross-certification = true;
        # Disable caching of passphrase for symmetrical ops
        no-symkey-cache = true;
        # Enable smartcard
        use-agent = true;
        # Disable recipient key ID in messages
        throw-keyids = true;
        # Default/trusted key ID to use (helpful with throw-keyids)
        default-key = myKey;
        # If no explicit recipient(s) are given, encrypt to the default key
        default-recipient-self = true;
        # If recipient(s) are given, also encrypt to self so we can also decrypt it, but don't mention it
        hidden-encrypt-to = myKey;
        # Always trust our own key
        trusted-key = myKey;
        # Keyserver URL
        keyserver = "hkps://keys.openpgp.org";
        # keyserver = "hkps://keyserver.ubuntu.com";
        # keyserver = "hkps://pgp.mit.edu";
        # keyserver = "hkps://keyoxide.org";
        # keyserver = "hkps://keybase.io";
        # keyserver = "hkps://keys.mailvelope.com";
      };
    };
    htop = {
      enable = true;
      settings = {
        enable_mouse = true;
        cpu_count_from_zero = true;
        hide_threads = true;
        hide_userland_threads = true;
        highlight_basename = true;
        vim_mode = true;
      };
    };
    kitty = {
      enable = true;
      font = {
        name = "Iosevka Nerd Font";
        size = 9;
      };
      keybindings = {
        "kitty_mod+v" = "paste_from_clipboard";
        "kitty_mod+plus" = "change_font_size all +1.0";
        "kitty_mod+minus" = "change_font_size all -1.0";
        "kitty_mod+backspace" = "change_font_size all 0";
        "kitty_mod+u" = "input_unicode_character";
      };
      theme = "Nord";
      settings = {
        background_opacity = "0.95";
        clear_all_shortcuts = true;
        scrollback_lines = 0;
        url_style = "none";
        enable_audio_bell = false;
        visual_bell_duration = "0.15";
        remember_window_size = false;
        window_padding_width = "12";
        initial_window_width = "108c";
        initial_window_height = "32c";
        # https://github.com/ryanoasis/nerd-fonts/wiki/Glyph-Sets-and-Code-Points#overview
        symbol_map = "${
            lib.strings.concatStringsSep "," [
              "U+23FB-U+23FE,U+2B58" # IEC Power Symbols
              "U+E000-U+E00A" # Pomicons
              "U+E0A0-U+E0A2,U+E0B0-U+E0B3" # Powerline
              "U+E0A3,U+E0B4-U+E0C8,U+E0CA,U+E0CC-U+E0D4" # Powerline Extra
              "U+E200-U+E2A9" # Font Awesome Extension
              "U+2665,U+26A1,U+F400-U+F4A8,U+F4A9" # Octicons
              "U+E300-U+E3EB" # Weather Icons
              "U+E5FA-U+E631" # Seti-UI + Custom
              "U+E700-U+E7C5" # Devicons
              "U+EA60-U+EBEB" # Codicons
              "U+F000-U+F2E0" # Font Awesome
              "U+F300-U+F32D" # Font Logos
              "U+F500-U+FD46" # Material Design
            ]
          } Symbols Nerd Font";
      };
    };
    less = {
      enable = true;
      keys = ''
        #line-edit
        ^P  up
        ^N  down
      '';
    };
    lesspipe.enable = true;
    mpv = {
      enable = true;
      config = {
        hwdec = "auto-safe";
        vo = "gpu";
        profile = "gpu-hq";
      };
    };
    nix-index.enable = true;
    password-store = {
      enable = true;
      package = pkgs.pass.withExtensions (exts:
        with exts; [
          (pass-otp.overrideAttrs (oldAttrs:
            let
              perl-pass-otp = with pkgs.perlPackages;
                buildPerlPackage {
                  pname = "Pass-OTP";
                  version = "1.5";
                  src = pkgs.fetchurl {
                    url =
                      "mirror://cpan/authors/id/J/JB/JBAIER/Pass-OTP-1.5.tar.gz";
                    sha256 = "GujxwmvfSXMAsX7LRiI7Q9YgsolIToeFRYEVAYFJeaM=";
                  };
                  buildInputs =
                    [ ConvertBase32 DigestHMAC DigestSHA3 MathBigInt ];
                  doCheck = false;
                };
            in {
              version = "1.2.0.r29.a364d2a";
              src = pkgs.fetchFromGitHub {
                owner = "tadfisher";
                repo = "pass-otp";
                rev = "a364d2a71ad24158a009c266102ce0d91149de67";
                sha256 = "q9m6vkn+IQyR/ZhtzvZii4uMZm1XVeBjJqlScaPsL34=";
              };
              buildInputs = [ perl-pass-otp ];
              patchPhase = ''
                sed -i -e 's|OATH=\$(which oathtool)|OATH=${perl-pass-otp}/bin/oathtool|' otp.bash
                sed -i -e 's|OTPTOOL=\$(which otptool)|OTPTOOL=${perl-pass-otp}/bin/otptool|' otp.bash
              '';
            }))
          pass-import
          pass-audit
          pass-update
          pass-checkup
          pass-genphrase
          pass-tomb
        ]);
      settings = {
        PASSWORD_STORE_GPG_OPTS = "--no-throw-keyids";
        PASSWORD_STORE_GENERATED_LENGTH = "128";
        PASSWORD_STORE_CHARACTER_SET = "[:print:]"; # All printable characters
      };
    };
    rofi = {
      enable = true;
      pass = {
        enable = true;
        extraConfig = let
          remove-binding = binding: str:
            let bindings = lib.strings.splitString "," str;
            in let newBindings = lib.lists.remove binding bindings;
            in lib.strings.concatStringsSep "," newBindings;
        in with config.programs.rofi.extraConfig; ''
          # rofi command. Make sure to have "$@" as last argument
          _rofi () {
              ${pkgs.rofi}/bin/rofi \
                -dpi 0 \
                -i \
                -kb-accept-custom "" \
                -kb-row-down "${remove-binding "Control+n" kb-row-down}" \
                -kb-row-up "${remove-binding "Control+p" kb-row-up}" \
                -kb-mode-complete "" \
                -kb-remove-char-back "BackSpace,Shift+BackSpace" \
                -kb-move-front "" \
                -kb-remove-to-sol "" \
                -no-auto-select \
                "$@"
          }

          # default command to generate passwords
          _pwgen () {
            ${pkgs.pwgen}/bin/pwgen -y "$@"
          }

          # image viewer to display qrcode of selected entry
          # qrencode is needed to generate the image and a viewer
          # that can read from pipes. Known viewers to work are feh and display
          _image_viewer () {
            ${pkgs.feh}/bin/feh -
          #    display
          }

          # It is possible to use wl-copy and wl-paste from wl-clipboard
          # Just uncomment the lines with wl-copy and wl-paste
          # and comment the xclip lines
          #
          _clip_in_primary() {
            ${pkgs.xclip}/bin/xclip
            # wl-copy-p
          }

          _clip_in_clipboard() {
            ${pkgs.xclip}/bin/xclip -selection clipboard
            # wl-copy
          }

          _clip_out_primary() {
            ${pkgs.xclip}/bin/xclip -o
            # wl-paste -p
          }

          _clip_out_clipboard() {
            ${pkgs.xclip}/bin/xclip --selection clipboard -o
            # wl-paste
          }

          # fields to be used
          URL_field='url'
          USERNAME_field='login'
          AUTOTYPE_field='autotype'

          # delay to be used for :delay keyword
          delay=2

          # rofi-pass needs to close itself before it can type passwords. Set delay here.
          wait=0.2

          # delay between keypresses when typing (in ms)
          xdotool_delay=12

          ## Programs to be used
          # Editor
          EDITOR='${config.home.sessionVariables.VISUAL}'

          # Browser
          BROWSER='${pkgs.xdg-utils}/bin/xdg-open'

          ## Misc settings

          default_do='menu' # menu, autotype, copyPass, typeUser, typePass, copyUser, copyUrl, viewEntry, typeMenu, actionMenu, copyMenu, openUrl
          auto_enter='false'
          notify='false'
          default_autotype='user :tab pass'

          # color of the help messages
          # leave empty for autodetection
          # https://github.com/carnager/rofi-pass/issues/226
          help_color="#4872FF"

          # Clipboard settings
          # Possible options: primary, clipboard, both
          clip=both

          # Seconds before clearing pass from clipboard
          clip_clear=45

          ## Options for generating new password entries

          # open new password entries in editor
          edit_new_pass="true"

          # default_user is also used for password files that have no user field.
          default_user=':filename'
          password_length=${config.programs.password-store.settings.PASSWORD_STORE_GENERATED_LENGTH}

          # Custom Keybindings
          autotype="Control+Return"
          type_user="Control+u"
          type_pass="Control+p"
          open_url="Control+l"
          copy_name="Alt+u"
          copy_url="Alt+l"
          copy_pass="Alt+p"
          show="Control+o"
          copy_menu="Control+c"
          action_menu="Control+a"
          type_menu="Control+t"
          help="Control+h"
          switch="Control+x"
          insert_pass="Control+n"
        '';
      };
      font = "Iosevka Nerd Font 12";
      terminal = terminal-emulator;
      extraConfig = {
        show-icons = true;
        # Remove some keys from the default bindings
        kb-accept-entry = "Control+m,Return,KP_Enter"; # Removed Control+j
        kb-remove-to-eol = ""; # Removed Control+k
        # Set our custom bindings
        kb-row-down = "Down,Control+n,Control+j";
        kb-row-up = "Up,Control+p,Control+k";
      };
      theme = let
        # Use `mkLiteral` for string-like values that should show without
        # quotes, e.g.:
        # {
        #   foo = "abc"; => foo: "abc";
        #   bar = mkLiteral "abc"; => bar: abc;
        # };
        inherit (config.lib.formats.rasi) mkLiteral;
      in {
        "*" = {
          bg0 = mkLiteral colors.nord0;
          bg1 = mkLiteral colors.nord1;
          fg0 = mkLiteral colors.nord4;
          accent-color = mkLiteral colors.nord8;
          urgent-color = mkLiteral colors.nord13;
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "@fg0";
          margin = 0;
          padding = 0;
          spacing = 0;
        };
        window = {
          location = mkLiteral "north";
          anchor = mkLiteral "north";
          y-offset = mkLiteral "280px";
          width = mkLiteral "40em";
          background-color = mkLiteral "@bg0";
        };
        inputbar = {
          spacing = mkLiteral "0.75em";
          padding = mkLiteral "0.75em";
          background-color = mkLiteral "@bg1";
        };
        prompt = {
          vertical-align = mkLiteral "0.5";
          text-color = mkLiteral "@accent-color";
        };
        entry = { vertical-align = mkLiteral "0.5"; };
        textbox = {
          padding = mkLiteral "0.75em";
          background-color = mkLiteral "@bg1";
        };
        listview = {
          padding = mkLiteral "0.5em 0";
          lines = 8;
          columns = 1;
          fixed-height = false;
        };
        element = {
          padding = mkLiteral "0.75em";
          spacing = mkLiteral "0.75em";
        };
        "element normal normal" = { text-color = mkLiteral "@fg0"; };
        "element normal urgent" = { text-color = mkLiteral "@urgent-color"; };
        "element normal active" = { text-color = mkLiteral "@accent-color"; };
        "element selected" = { text-color = mkLiteral "@bg0"; };
        "element selected normal" = {
          background-color = mkLiteral "@accent-color";
        };
        "element selected active" = {
          background-color = mkLiteral "@accent-color";
        };
        "element selected urgent" = {
          background-color = mkLiteral "@urgent-color";
        };
        element-icon = {
          vertical-align = mkLiteral "0.5";
          size = mkLiteral "1.5em";
        };
        element-text = {
          vertical-align = mkLiteral "0.5";
          text-color = mkLiteral "inherit";
        };
      };
    };
    ssh = {
      enable = true;
      # Enable compression for slow networks, for fast ones this slows it down
      # compression = true;
      # Share connections to same host
      controlMaster = "auto";
      controlPath = "\${XDG_RUNTIME_DIR}/master-%r@%n:%p";
      controlPersist = "yes";
      extraConfig = ''
        # Only attempt explicitly specified identities
        IdentitiesOnly yes
        IdentityFile ~/.ssh/id_ed25519

        # By default add the key to the agent so we're not asked for the passphrase again
        AddKeysToAgent yes

        # Use a faster cipher
        Ciphers aes128-gcm@openssh.com,aes256-gcm@openssh.com,chacha20-poly1305@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr

        # Login more quickly by bypassing IPv6 lookup
        AddressFamily inet
      '';
      includes = [ "config_local" ];
    };
    starship = {
      enable = true;
      settings = {
        aws.symbol = " ";
        azure.symbol = "ﴃ ";
        c.symbol = " ";
        container.symbol = " ";
        dart.symbol = " ";
        docker_context.symbol = " ";
        dotnet.symbol = " ";
        elixir.symbol = " ";
        elm.symbol = " ";
        gcloud.symbol = " ";
        git_branch.symbol = " ";
        git_commit.tag_symbol = " ";
        golang.symbol = " ";
        haskell.symbol = " ";
        # hostname.ssh_symbol = " ";
        hg_branch.symbol = " ";
        java.symbol = " ";
        jobs.symbol = " ";
        julia.symbol = " ";
        lua.symbol = " ";
        memory_usage.symbol = " ";
        nim.symbol = " ";
        nix_shell.symbol = " ";
        nodejs.symbol = " ";
        package.symbol = " ";
        perl.symbol = " ";
        php.symbol = " ";
        python.symbol = " ";
        ruby.symbol = " ";
        rust.symbol = " ";
        scala.symbol = " ";
        swift.symbol = " ";
        custom.direnv = {
          format = "[\\[direnv\\]]($style) ";
          style = "fg:yellow dimmed";
          when = "env | grep -E '^DIRENV_FILE='";
        };
      };
    };
    tmux = {
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
        bind-key s choose-tree -sZ -f '#{?session_attached,0,1}'

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
        nord
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
          plugin = mkTmuxPlugin {
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
          };
        }
        {
          plugin = extrakto;
          extraConfig = ''
            set-option -g @extrakto_fzf_tool '${pkgs.fzf}/bin/fzf'
            set-option -g @extrakto_clip_tool '${pkgs.xsel}/bin/xsel --input --clipboard' # works better for nvim
            set-option -g @extrakto_copy_key 'tab'
            set-option -g @extrakto_insert_key 'enter'
          '';
        }
        {
          plugin = mkTmuxPlugin {
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
    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      extraConfig = ''
        " use visual terminal bell
        set vb

        " line numbers
        set relativenumber
        set number

        " Don't break words when wrapping lines
        set linebreak

        " make wrapped lines more obvious
        let &showbreak="↳ "
        set cpoptions+=n

        " Make tabs, non-breaking spaces and trailing white space visible
        set list
        " Use a Box Drawings Light Quadruple Dash Vertical (0x250A) + Space to
        " show a Tab, a Middle Dot (0x00B7) for trailing spaces, and the negation
        " symbol (0x00AC) for non-breaking spaces
        set listchars=tab:│\ ,trail:·,extends:→,precedes:←,nbsp:¬
        " Use nicer window split separator (like tmux)
        set fillchars+=vert:│

        " Highlight the line I'm on
        set cursorline

        " Set cursor depending on mode
        set guicursor=n-v-c:block-Cursor/lCursor-blinkon0,i-ci:ver25-Cursor/lCursor,r-cr:hor20-Cursor/lCursor

        " Show the textwidth visually
        set colorcolumn=+1,+2

        " Highlight matching paired delimiter
        set showmatch

        " display incomplete commands
        set showcmd

        " Set comments to be italic
        highlight Comment gui=italic cterm=italic
        autocmd! ColorScheme * highlight Comment gui=italic cterm=italic

        " Concealing
        set conceallevel=1
        set concealcursor=

        " Powerline-style status- and tab/buffer-line
        set showtabline=2 " Always display the tabline, even if there is only one tab
        set noshowmode " Hide the default mode text (e.g. -- INSERT -- below the statusline)

        " Use undercurl for spelling error highlight
        let &t_Cs = "\e[4:3m"
        let &t_Ce = "\e[4:0m"
        hi SpellBad gui=undercurl term=undercurl cterm=undercurl

        " Set the leader needs to be done early, because any mappings that use
        " <Leader> will use the value of <Leader> that was defined when they’re
        " defined.
        let mapleader="\<Space>"
        let maplocalleader="-"

        " recall newer command-line using current characters as search pattern
        cnoremap <C-N> <Down>
        " recall previous (older) command-line using current characters as search pattern
        cnoremap <C-P> <Up>

        " Let brace movement work even when braces aren’t at col 0
        map [[ ?{<CR>w99[{
        map ][ /}<CR>b99]}
        map ]] j0[[%/{<CR>
        map [] k$][%?}<CR>

        " Don't use Ex mode, use Q for formatting
        map Q gq

        " CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first break undo,
        " so that you can undo CTRL-U after inserting a line break.
        inoremap <C-U> <C-G>u<C-U>

        " Write with root permissions
        cmap w!! w !sudo tee > /dev/null %

        " Enable mouse
        set mouse=a

        " set tabs to display as 2 spaces wide (might be overwritten by
        " .editorconfig files)
        set tabstop=2 softtabstop=2 shiftwidth=2 noexpandtab
        set shiftround

        " When wrap is off, horizontally scroll a decent amount.
        set sidescroll=16

        " check final line for Vim settings
        set modelines=1

        " ignore case sensitivity in searching
        set ignorecase

        " smart case sensitivity in searching
        set smartcase

        " better command line completion
        set wildmode=longest,full
        set fileignorecase
        set wildignorecase

        " Ingore backup files & git directories
        set wildignore+=*~,.git

        " Enable code folding
        set foldenable
        set foldlevelstart=10
        set foldnestmax=10
        set foldmethod=indent
        set foldcolumn=2

        " Switch buffers even if modified
        set hidden

        " better split window locations
        set splitright
        set splitbelow

        " Stop backup files from littering all over the system
        let myBackupDir = '${config.xdg.cacheHome}/vim/backup/'
        call system('mkdir -p ' . myBackupDir)
        let &backupdir = myBackupDir . ',' . &backupdir
        " Keep backup files
        set backup
        " Do it in a way that is compatible with file-watchers
        set backupcopy=yes

        " Stop swap files from littering all over the system
        let mySwapDir = '${config.xdg.cacheHome}/vim/swap/'
        call system('mkdir -p ' . mySwapDir)
        let &directory = mySwapDir . ',' . &directory

        " Persistent undo
        if has('persistent_undo')
          let myUndoDir = '${config.xdg.cacheHome}/vim/undo/'
          " Create dirs
          call system('mkdir -p ' . myUndoDir)
          let &undodir = myUndoDir
          set undofile
        endif

        " Spell check & word completion
        set spell spelllang=en_gb
        set complete+=kspell

        " Open file at last cursor position
        augroup cursorpos
          autocmd!
          " When editing a file, always jump to the last known cursor position.
          " Don't do it when the position is invalid or when inside an event
          " handler (happens when dropping a file on gvim). Also don't do it
          " when the mark is in the first line, that is the default position
          " when opening a file.
          autocmd BufReadPost *
            \ if line("'\"") > 1 && line("'\"") <= line("$") |
            \   exe "normal! g`\"" |
            \ endif
        augroup END

        " Faster update for Git Gutter and CoC
        set updatetime=300

        " Faster macro execution
        set lazyredraw

        set shell=/bin/sh
      '';
      coc.enable = true;
      plugins = with pkgs.vimPlugins; [
        {
          plugin = vim-gitgutter;
          config = ''
            let g:gitgutter_map_keys = 0
            let g:gitgutter_sign_priority = 9
          '';
        }
        {
          plugin = nord-vim;
          config = ''
            colorscheme nord
          '';
        }
        {
          plugin = vim-airline;
          config = ''
            let g:airline_powerline_fonts = 1 " Use powerline glyphs
            let g:airline#extensions#tabline#enabled = 1 " Use tabline
            let g:airline#extensions#tabline#show_tabs = 1 " Always show tabline
            let g:airline#extensions#tabline#show_buffers = 1 " Show buffers when no tabs
            let g:airline#extensions#whitespace#mixed_indent_algo = 2 " Allow spaces after tabs for alignment
            let g:airline#extensions#c_like_langs = ['c', 'cpp', 'cuda', 'go', 'javascript', 'javascript.jsx', 'ld', 'php']
          '';
        }
        vim-airline-themes
        vim-css-color
        vim-repeat
        vim-rsi
        direnv-vim
        vim-tmux-focus-events
        matchit-zip
        vim-unimpaired
        vim-sensible
        editorconfig-vim
        fastfold
        targets-vim
        vim-commentary
        vim-speeddating
        vim-surround
        {
          plugin = ale;
          config = ''
            let g:ale_command_wrapper = 'env NODE_ENV=development'
            let g:airline#extensions#ale#enabled = 1
            let g:ale_sign_priority=30
            let g:ale_sign_warning = "⚠️"
            let g:ale_sign_error = "🚨"
            let g:ale_echo_msg_error_str = "🚨"
            let g:ale_echo_msg_warning_str = "⚠️"
            let g:ale_echo_msg_format = '%severity%  %s [%linter%] %code%'
            let g:ale_fix_on_save = 1
            let javascript_fixers = ['prettier', 'importjs', 'eslint']
            let css_fixers = ['prettier', 'stylelint']
            let g:ale_fixers = {
            	\ 'javascript': javascript_fixers,
            	\ 'javascript.jsx': javascript_fixers,
            	\ 'javascriptreact': javascript_fixers,
            	\ 'typescript': javascript_fixers,
            	\ 'typescript.jsx': javascript_fixers,
            	\ 'typescriptreact': javascript_fixers,
            	\ 'css': css_fixers,
            	\ 'scss': css_fixers,
            	\ 'json': ['prettier'],
            	\ 'markdown': ['prettier'],
            	\ 'yaml': ['prettier']
            \}
            let g:ale_javascript_eslint_suppress_eslintignore = 1
            " the `flow` linter uses an old API; prefer `flow-language-server`
            let g:ale_linters_ignore = ['flow']
          '';
        }
        {
          plugin = nerdtree;
          config = ''
            let g:NERDTreeShowHidden = 1
            let g:NERDTreeMinimalUI = 1
            nnoremap <F8> :NERDTreeToggle<CR>
          '';
        }
        {
          plugin = nerdtree-git-plugin;
          config = ''
            let g:NTPNames = ['.git*', 'package.json']
            let g:NTPNamesDirs = ['.git']
          '';
        }
        {
          plugin = vim-rooter;
          config = ''
            let g:rooter_patterns = ['.git', '.git/', 'package.json']
            let g:rooter_silent_chdir = 1
          '';
        }
        {
          plugin = ack-vim;
          config = ''
            if executable('ag')
            	let g:ackprg = "ag --nogroup --nocolor --column --hidden"
            	nnoremap <Leader>a :Ack! |
            elseif executable('ack') || executable ('ack-grep')
            	nnoremap <Leader>a :Ack! |
            else
            	nnoremap <Leader>a :grep |
            endif
          '';
        }
        vim-fugitive
        {
          plugin = delimitMate;
          config = ''
            let delimitMate_expand_space = 1
            let delimitMate_expand_cr = 2
            let delimitMate_balance_matchpairs = 1
            let delimitMate_nesting_quotes = ['`']
          '';
        }
        vim-tmux
        vim-tridactyl
        vim-polyglot
        {
          plugin = vim-devicons;
          config = ''
            let g:webdevicons_enable_nerdtree = 1
            let g:webdevicons_conceal_nerdtree_brackets = 1
            let g:WebDevIconsNerdTreeGitPluginForceVAlign = 1
            let g:webdevicons_enable_ctrlp = 1
            let g:webdevicons_enable_startify = 1
            let g:WebDevIconsUnicodeDecorateFolderNodes = 1
            let g:DevIconsEnableFoldersOpenClose = 1
            if exists("g:loaded_webdevicons")
            	call webdevicons#refresh()
            endif
          '';
        }
      ];
    };
    vscode = with pkgs; {
      enable = true;
      package = vscode-fhs;
      extensions = (with vscode-extensions; [
        bbenoist.nix
        vscodevim.vim
        ms-vscode-remote.remote-ssh
      ]) ++ vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "direnv";
          publisher = "mkhl";
          version = "0.6.1";
          sha256 = "5/Tqpn/7byl+z2ATflgKV1+rhdqj+XMEZNbGwDmGwLQ=";
        }
        {
          name = "remote-containers";
          publisher = "ms-vscode-remote";
          version = "0.247.0";
          sha256 = "gWFNjkx2+zjkpKDC5a1qIZ5SbcDN8ahtXDPX1upWUg8=";
        }
      ];
    };
    zathura = {
      enable = true;
      options = {
        # Use the title bar for status
        guioptions = "";
        window-title-basename = true;
        window-title-page = true;

        # Better dark mode
        recolor-darkcolor = "#CCCCCC";
        recolor-keephue = true;

        # Better selection
        selection-clipboard = "clipboard";
        selection-notification = false;
      };
    };
  };

  services = {
    dunst = {
      enable = true;
      settings = {
        global = {
          follow = "keyboard";
          width = "(0, 500)";
          height = 100;
          offset = "0x24";
          separator_height = 4;
          frame_width = 0;
          separator_color = "#00000000";
          font = "Iosevka Nerd Font 10";
          format = ''
            <b>%s</b>
            %b'';
          vertical_alignment = "top";
          show_age_threshold = "5m";
          icon_position = "left";
          max_icon_size = 60;
          icon_path = "${pkgs.zafiro-icons}/share/icons/Zafiro-icons";
          enable_recursive_icon_lookup = "true";
          dmenu = "${pkgs.rofi}/bin/rofi -dmenu -p dunst";
          mouse_left_click = "close_current";
          mouse_middle_click = "context";
          mouse_right_click = "do_action";
          fullscreen = "pushback";
          timeout = "30s";
          startup_notification = false;
          markup = "full";
          foreground = colors.nord6;
        };
        urgency_low = { background = "${colors.nord3}99"; };
        urgency_normal = { background = "${colors.nord10}99"; };
        urgency_critical = {
          background = "${colors.nord11}99";
          fullscreen = "show";
          timeout = 0;
        };
      };
    };
    emacs = {
      enable = true;
      package = my-doom-emacs;
      client.enable = true;
    };
    flameshot.enable = true;
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
      pinentryFlavor = "gnome3";
      defaultCacheTtl = 0;
      maxCacheTtl = 0;
      defaultCacheTtlSsh = 0;
      maxCacheTtlSsh = 0;
    };
    network-manager-applet.enable = true;
    nextcloud-client.enable = true;
    password-store-sync.enable = true;
    picom = {
      enable = true;
      package = let picomPkg = pkgs.picom;
      in with pkgs;
      picomPkg // (symlinkJoin {
        name = "picom";
        paths = [ picomPkg ];
        buildInputs = [ makeBinaryWrapper ];
        postBuild = ''
          # Needed for the service EnvironmentFile to work
          wrapProgram $out/bin/picom \
            --add-flags \''${ARG_0:+\"\$ARG_0\"} \
            --add-flags \''${ARG_1:+\"\$ARG_1\"}
        '';
      });
      backend = "glx";
      fade = true;
      fadeDelta = 3;
      inactiveOpacity = 0.95;
      menuOpacity = 0.95;
      shadow = true;
      shadowOffsets = [ (-7) (-7) ];
      shadowExclude = [
        # unknown windows
        "! name~=''"
        # shaped windows
        "bounding_shaped && !rounded_corners"
        # no shadow on i3 frames
        "class_g = 'i3-frame'"
        # hidden windows
        "_NET_WM_STATE@:32a *= '_NET_WM_STATE_HIDDEN'"
        # stacked / tabbed windows
        "_NET_WM_STATE@[0]:a = '_NET_WM_STATE@_MAXIMIZED_VERT'"
        "_NET_WM_STATE@[0]:a = '_NET_WM_STATE@_MAXIMIZED_HORZ'"
        # GTK
        "_GTK_FRAME_EXTENTS@:c"
        "class_g ~= 'xdg-desktop-portal' && _NET_FRAME_EXTENTS@:c && window_type = 'dialog'"
        "class_g ~= 'xdg-desktop-portal' && window_type = 'menu'"
        "_NET_FRAME_EXTENTS@:c && WM_WINDOW_ROLE@:s = 'Popup'"
        # Mozilla fixes
        "class_i = 'Firefox' && window_type = 'utility'"
        "class_i = 'Firefox' && window_type = 'popup_menu'"
        "class_i = 'Thunderbird' && window_type = 'utility'"
        "class_i = 'Thunderbird' && window_type = 'popup_menu'"
        # notifications
        "_NET_WM_WINDOW_TYPE@:32a *= '_NET_WM_WINDOW_TYPE_NOTIFICATION'"
        # Zoom
        "name = 'cpt_frame_xcb_window'"
        "class_g *?= 'zoom' && name *?= 'meeting'"
      ];
      opacityRules =
        # Only apply these opacity rules if the windows are not hidden
        map
        (str: str + " && !(_NET_WM_STATE@[*]:a *= '_NET_WM_STATE_HIDDEN')") [
          "100:class_g *?= 'zoom' && name *?= 'meeting'"
          "100:role = 'browser' && name ^= 'Meet -'"
          "100:role = 'browser' && name ^= 'Netflix'"
          "95:class_g = 'Emacs'"
        ] ++ [ "0:_NET_WM_STATE@[*]:a *= '_NET_WM_STATE_HIDDEN'" ];
      vSync = true;
      settings = {
        inactive-dim = 0.2;
        blur = {
          method = "dual_kawase";
          strength = 5;
        };
        blur-background-exclude = [
          # unknown windows
          "! name~=''"
          # shaped windows
          "bounding_shaped"
          # hidden windows
          "_NET_WM_STATE@[*]:a *= '_NET_WM_STATE_HIDDEN'"
          # stacked / tabbed windows
          "_NET_WM_STATE@[0]:a = '_NET_WM_STATE@_MAXIMIZED_VERT'"
          "_NET_WM_STATE@[0]:a = '_NET_WM_STATE@_MAXIMIZED_HORZ'"
          # GTK
          "_GTK_FRAME_EXTENTS@:c"
          "class_g ~= 'xdg-desktop-portal' && _NET_FRAME_EXTENTS@:c && window_type = 'dialog'"
          "class_g ~= 'xdg-desktop-portal' && window_type = 'menu'"
          "_NET_FRAME_EXTENTS@:c && WM_WINDOW_ROLE@:s = 'Popup'"
          # Mozilla fixes
          "class_i = 'Firefox' && window_type = 'utility'"
          "class_i = 'Firefox' && window_type = 'popup_menu'"
          "class_i = 'Thunderbird' && window_type = 'utility'"
          "class_i = 'Thunderbird' && window_type = 'popup_menu'"
          # Zoom
          "name = 'cpt_frame_xcb_window'"
          "class_g *?= 'zoom' && name *?= 'meeting'"
        ];
        mark-wmwin-focused = true;
        mark-ovredir-focused = true;
        detect-client-opacity = true;
        detect-transient = true;
        glx-no-stencil = true;
        glx-no-rebind-pixmap = true;
        use-damage = true;
        shadow-radius = 7;
        xinerama-shadow-crop = true;
        xrender-sync-fence = true;
        focus-exclude = [
          "name = 'Picture-in-Picture'"
          "_NET_WM_STATE@[*]:a *= '_NET_WM_STATE_FULLSCREEN'"
          "class_g *?= 'zoom' && name *?= 'meeting'"
          "role = 'browser' && name ^= 'Netflix'"
          "role = 'browser' && name ^= 'Meet -'"
        ];
        detect-rounded-corners = true;
        # corner-radius = 10;
        # rounded-corners-exclude = [
        #   # notifications
        #   "_NET_WM_WINDOW_TYPE@:32a *= '_NET_WM_WINDOW_TYPE_DOCK'",
        # ];
      };
    };
    polybar = {
      enable = true;
      package = pkgs.polybar.override {
        i3GapsSupport = true;
        mpdSupport = true;
      };
      settings = let superColors = colors;
      in let
        colors = superColors // {
          background = colors.nord0;
          background-alt = colors.nord1;
          foreground = colors.nord9;
          foreground-alt = colors.nord10;
          primary = colors.nord9;
          secondary = colors.nord10;
          alert = colors.nord12;
        };
      in {
        settings = { screenchange-reload = true; };
        "bar/top" = {
          inherit (colors) background foreground;
          monitor = "\${env:MONITOR:}";
          dpi = 0;
          width = 1920;
          height = 24;

          modules-left = "i3 title";
          # modules-center = "yubikey mpd";
          modules-center = "yubikey";
          modules-right = "pipewire-simple xkeyboard battery date";

          font-0 = "Symbols Nerd Font:size=18;3";
          font-1 = "Symbols Nerd Font:size=10;2";
          font-2 = "Iosevka Nerd Font:size=8;2";

          tray-position = "right";
          tray-padding = 2;
          tray-maxsize = 18;
          tray-foreground = colors.nord4;
          tray-background = colors.background;
          tray-prefix = "";
          tray-prefix-font = 1;
          tray-prefix-foreground = colors.nord3;
          tray-prefix-background = colors.nord0;
        };
        "module/i3" = {
          type = "internal/i3";
          strip-wsnumbers = true;
          format = "<label-state><label-mode>";
          format-foreground = colors.nord0;
          format-background = colors.nord3;
          format-padding-left = 1;
          format-prefix = ''" "'';
          format-suffix = "";
          format-suffix-font = 1;
          format-suffix-foreground = colors.nord3;
          format-suffix-background = colors.nord1;
          index-sort = true;
          enable-scroll = false;
          wrapping-scroll = false;

          label-mode-padding = 1;
          label-mode-font = 2;
          label-mode-foreground = colors.nord6;
          label-mode-background = "\${self.format-background}";

          # unfocused = Inactive workspace on any monitor
          label-unfocused = "%name%";
          label-unfocused-font = 2;
          label-unfocused-foreground = "\${self.format-foreground}";
          label-unfocused-background = "\${self.format-background}";
          label-unfocused-padding = 1;

          # focused = Active workspace on focused monitor
          label-focused = "%name%";
          label-focused-font = 2;
          label-focused-foreground = colors.nord6;
          label-focused-background = "\${self.format-background}";
          label-focused-padding = 1;

          # visible = Active workspace on unfocused monitor
          label-visible = "%name%";
          label-visible-font = 2;
          label-visible-foreground = colors.nord10;
          label-visible-background = "\${self.format-background}";
          label-visible-padding = 1;

          # urgent = Workspace with urgency hint set
          label-urgent = "%name%";
          label-urgent-font = 2;
          label-urgent-foreground = colors.nord13;
          label-urgent-background = "\${self.format-background}";
          label-urgent-padding = 1;
        };
        "module/title" = {
          type = "internal/xwindow";
          format-background = colors.nord1;
          format-suffix = "";
          format-suffix-font = 1;
          format-suffix-foreground = colors.nord1;
          format-suffix-background = colors.background;
          # Prepend a zero-width space to keep rendering
          # the suffix even on an empty workspace
          label = "​%title:0:50:…%";
          label-foreground = colors.nord4;
          label-background = "\${self.format-background}";
          label-padding = 1;
          label-font = 3;
        };
        "module/mpd" = {
          type = "internal/mpd";
          format-online =
            "<label-song> <bar-progress> <label-time>  <icon-prev> <icon-seekb> <icon-stop> <toggle> <icon-seekf> <icon-next>  <icon-repeat> <icon-random>";
          format-online-foreground = colors.nord1;

          icon-foreground = "\${self.format-online-foreground}";

          icon-play = "⏵";
          icon-pause = "⏸";
          icon-stop = "⏹";
          icon-prev = "⏮";
          icon-next = "⏭";
          icon-seekb = "⏪";
          icon-seekf = "⏩";
          icon-random = "🔀";
          icon-repeat = "🔁";

          icon-play-foreground = "\${self.icon-foreground}";
          icon-pause-foreground = "\${self.icon-foreground}";
          icon-stop-foreground = "\${self.icon-foreground}";
          icon-prev-foreground = "\${self.icon-foreground}";
          icon-next-foreground = "\${self.icon-foreground}";
          icon-seekb-foreground = "\${self.icon-foreground}";
          icon-seekf-foreground = "\${self.icon-foreground}";
          icon-random-foreground = "\${self.icon-foreground}";
          icon-repeat-foreground = "\${self.icon-foreground}";

          toggle-off-foreground = "\${self.icon-foreground}";
          toggle-on-foreground = colors.nord4;

          label-song-maxlen = 50;
          label-song-ellipsis = true;
          label-song-font = 3;
          label-song-foreground = colors.nord4;

          label-time-font = 3;
          label-time-foreground = colors.nord4;

          bar-progress-width = 30;
          bar-progress-indicator = "|";
          bar-progress-indicator-foreground = colors.nord2;
          bar-progress-fill = "─";
          bar-progress-fill-foreground = colors.nord4;
          bar-progress-empty = "─";
          bar-progress-empty-foreground = colors.nord3;
        };
        "module/xkeyboard" = {
          type = "internal/xkeyboard";
          blacklist-0 = "num lock";

          format-prefix = " ";
          format-prefix-foreground = colors.foreground-alt;
          format-prefix-underline = colors.secondary;

          label-layout = "%name%";
          label-layout-font = 3;
          label-layout-underline = colors.secondary;

          label-indicator-padding = 2;
          label-indicator-margin = 1;
          label-indicator-background = colors.secondary;
          label-indicator-underline = colors.secondary;
        };
        "module/date" = {
          type = "internal/date";
          interval = 1;

          date = "";
          date-alt = " %Y-%m-%d";

          time = "%H:%M";
          time-alt = "%H:%M:%S";

          format-prefix = "|";
          format-prefix-foreground = colors.foreground-alt;
          format-underline = colors.nord10;

          label = "%date% %time%";
          label-font = 3;
        };
        "module/battery" = {
          type = "internal/battery";
          battery = "BAT0";
          adapter = "ADP1";
          full-at = "98";
          label-font = 3;

          format-charging = "<animation-charging> <label-charging>";
          format-charging-underline = colors.nord13;

          format-discharging = "<ramp-capacity> <label-discharging>";
          format-discharging-underline = "\${self.format-charging-underline}";

          format-full-prefix = " ";
          format-full-prefix-foreground = colors.foreground-alt;
          format-full-underline = "\${self.format-charging-underline}";

          ramp-capacity-0 = "";
          ramp-capacity-1 = "";
          ramp-capacity-2 = "";
          ramp-capacity-foreground = colors.foreground-alt;

          animation-charging-0 = "";
          animation-charging-1 = "";
          animation-charging-2 = "";
          animation-charging-foreground = colors.foreground-alt;
          animation-charging-framerate = 750;
        };
        "module/yubikey" = let
          indicator-script =
            pkgs.writeShellScript "yubikey-indicator-script.sh" ''
              ${pkgs.nmap}/bin/ncat --unixsock $XDG_RUNTIME_DIR/yubikey-touch-detector.socket | while read -n5 message; do
                [[ $message = *1 ]] && echo "                " || echo ""
              done
            '';
        in {
          type = "custom/script";
          exec = indicator-script;
          tail = true;
          format-background = colors.alert;
          format-foreground = colors.background;
          label-font = 2;
          format-prefix = "";
          format-prefix-font = 1;
          format-prefix-foreground = colors.alert;
          format-prefix-background = colors.background;
          format-suffix = "";
          format-suffix-font = 1;
          format-suffix-foreground = colors.alert;
          format-suffix-background = colors.background;
        };
        "module/pipewire-simple" = let
          pipewire-simple = pkgs.writeShellScript "pipewire-simple.sh" ''
            getDefaultSink() {
                defaultSink=$(${pkgs.pulseaudio}/bin/pactl info | ${pkgs.gawk}/bin/awk -F : '/Default Sink:/{print $2}')
                description=$(${pkgs.pulseaudio}/bin/pactl list sinks | ${pkgs.gnused}/bin/sed -n "/''${defaultSink}/,/Description/p; /Description/q" | ${pkgs.gnused}/bin/sed -n 's/^.*Description: \(.*\)$/\1/p')
                echo "''${description}"
            }

            getDefaultSource() {
                defaultSource=$(${pkgs.pulseaudio}/bin/pactl info | ${pkgs.gawk}/bin/awk -F : '/Default Source:/{print $2}')
                description=$(${pkgs.pulseaudio}/bin/pactl list sources | ${pkgs.gnused}/bin/sed -n "/''${defaultSource}/,/Description/p; /Description/q" | ${pkgs.gnused}/bin/sed -n 's/^.*Description: \(.*\)$/\1/p')
                echo "''${description}"
            }

            VOLUME=$(${pkgs.pamixer}/bin/pamixer --get-volume-human)
            SINK=$(getDefaultSink)
            SOURCE=$(getDefaultSource)

            case $1 in
                "--up")
                    ${pkgs.pamixer}/bin/pamixer --increase 5
                    ;;
                "--down")
                    ${pkgs.pamixer}/bin/pamixer --decrease 5
                    ;;
                "--mute")
                    ${pkgs.pamixer}/bin/pamixer --toggle-mute
                    ;;
                *)
                    echo "Source: ''${SOURCE} | Sink: ''${VOLUME} ''${SINK}"
            esac
          '';
        in {
          type = "custom/script";
          label = "%output%";
          label-font = 3;
          interval = 2;
          click-right = "exec ${pkgs.pavucontrol}/bin/pavucontrol &";
          click-left = "${pipewire-simple} --mute &";
          scroll-up = "${pipewire-simple} --up &";
          scroll-down = "${pipewire-simple} --down &";
          exec = pipewire-simple;
        };
      };
      script = ''
        # Launch bar on each monitor
        for m in $(polybar --list-monitors | ${pkgs.coreutils}/bin/cut -d":" -f1); do
          MONITOR=$m polybar --reload top &
        done
      '';
    };
    redshift = {
      enable = true;
      tray = true;
      provider = "geoclue2";
      settings.redshift.adjustment-method = "randr";
    };
    sxhkd = {
      enable = true;
      keybindings = let
        flameshot-region = (pkgs.writeShellScript "flameshot-region" ''
          if [ "$1" = "activewindow" ]; then
            # Get active window geometry
            eval $(${pkgs.xdotool}/bin/xdotool getactivewindow getwindowgeometry --shell)
            REGION="''${WIDTH}x''${HEIGHT}+''${X}+''${Y}"
          elif [ "$1" = "selectwindow" ]; then
            # Let the user select a window and get its geometry
            eval $(${pkgs.xdotool}/bin/xdotool selectwindow getwindowgeometry --shell)
            REGION="''${WIDTH}x''${HEIGHT}+''${X}+''${Y}"
          else
            # Get current screen
            SCREEN=$(${pkgs.xdotool}/bin/xdotool get_desktop)
            REGION="screen''${SCREEN}"
          fi

          # Launch the screenshot gui
          ${pkgs.flameshot}/bin/flameshot gui --region "$REGION"
        '');
      in {
        # Screenshot
        "Print" = "${pkgs.flameshot}/bin/flameshot gui";
        "super + Print" = "${flameshot-region} activewindow";
        "super + shift + Print" = "${flameshot-region}";

        # Notifications
        "super + dollar" = "${pkgs.dunst}/bin/dunstctl close";
        "super + shift + dollar" = "${pkgs.dunst}/bin/dunstctl close-all";
        "super + ampersand" = "${pkgs.dunst}/bin/dunstctl history-pop";
        "super + m" = "${pkgs.dunst}/bin/dunstctl action 0";
        "super + shift + m" = "${pkgs.dunst}/bin/dunstctl context";

        # Toggle grayscale
        "super + shift + g" = "${pkgs.writeShellScript "toggle-grayscale.sh" ''
          if [ -f ${config.xdg.dataHome}/picom/env ]; then
            rm ${config.xdg.dataHome}/picom/env
          else
            ln -s ${config.xdg.configHome}/picom/env-grayscale ${config.xdg.dataHome}/picom/env
          fi
          ${pkgs.systemd}/bin/systemctl --user restart picom.service
        ''}";

        # Toggle dark mode
        "super + shift + d" = "${pkgs.writeShellScript "toggle-dark-mode.sh" ''
          dark_mode_on=$( [ "$(${pkgs.xfce.xfconf}/bin/xfconf-query -c xsettings -p /Net/ThemeName)" = "Nordic" ]; echo $? )

          if [ $dark_mode_on = 0 ]; then
            ${config.xdg.dataHome}/light-mode.d/gtk-theme.sh
          else
            ${config.xdg.dataHome}/dark-mode.d/gtk-theme.sh
          fi
        ''}";

        # Transparency controls
        "super + Home" = "${pkgs.picom}/bin/picom-trans --current --delete";
        "super + button2" = "${pkgs.picom}/bin/picom-trans --current --delete";
        "super + Prior" =
          "${pkgs.picom}/bin/picom-trans --current --opacity=-5";
        "super + button5" =
          "${pkgs.picom}/bin/picom-trans --current --opacity=-5";
        "super + Next" = "${pkgs.picom}/bin/picom-trans --current --opacity=+5";
        "super + button4" =
          "${pkgs.picom}/bin/picom-trans --current --opacity=+5";
        "super + End" = "${pkgs.picom}/bin/picom-trans --current --opacity=100";
        "super + shift + button2" =
          "${pkgs.picom}/bin/picom-trans --current --opacity=100";

        # Lock screen
        "super + x" = "${pkgs.systemd}/bin/loginctl lock-session";

        # Programs
        "super + p" = "${pkgs.rofi-pass}/bin/rofi-pass";
        "super + e" =
          "${config.programs.emacs.package}/bin/emacsclient –eval '(emacs-everywhere)'";

        # Audio controls
        "XF86AudioRaiseVolume" =
          "${pkgs.pulseaudio}/bin/pactl set-sink-volume 0 +5%";
        "XF86AudioLowerVolume" =
          "${pkgs.pulseaudio}/bin/pactl set-sink-volume 0 -5%";
        "XF86AudioMute" = "${pkgs.pulseaudio}/bin/pactl set-sink-mute 0 toggle";
        "XF86AudioPlay" = "${pkgs.playerctl}/bin/playerctl play-pause";
        "XF86AudioPause" = "${pkgs.playerctl}/bin/playerctl pause";
        "XF86AudioNext" = "${pkgs.playerctl}/bin/playerctl next";
        "XF86AudioPrev" = "${pkgs.playerctl}/bin/playerctl previous";
        "XF86AudioForward" = "${pkgs.playerctl}/bin/playerctl position 5+";
        "XF86AudioRewind" = "${pkgs.playerctl}/bin/playerctl position 5-";

        # Screen brightness controls
        "XF86MonBrightnessUp" =
          "${pkgs.brightnessctl}/bin/brightnessctl set 5%+";
        "XF86MonBrightnessDown" =
          "${pkgs.brightnessctl}/bin/brightnessctl set 5%-";
      };
    };
    vscode-server.enable = true;
    unclutter = {
      enable = true;
      threshold = 10;
      extraOptions = [ "ignore-scrolling" ];
    };
  };

  xsession = {
    enable = true;
    initExtra = let backgroundImage = ../backgrounds/martian-terrain.jpg;
    in "${pkgs.feh}/bin/feh --no-fehbg --no-xinerama --bg-fill ${backgroundImage} &";
    windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;
      config = let
        # Define workspace names
        workspace1 = ''number "1: "'';
        workspace2 = ''number "2: "'';
        workspace3 = ''number "3: "'';
        workspace4 = ''number "4: "'';
        workspace5 = ''number "5: "'';
        workspace6 = ''number "6: 6"'';
        workspace7 = ''number "7: 7"'';
        workspace8 = ''number "8: 8"'';
        workspace9 = ''number "9: "'';
        workspace10 = ''number "10: "'';
        # Gaps modes
        mode-gaps = "Gaps: (o) outer, (i) inner";
        mode-gaps-inner = "Inner Gaps: +|-|0 (local), Shift + +|-|0 (global)";
        mode-gaps-outer = "Outer Gaps: +|-|0 (local), Shift + +|-|0 (global)";
      in {
        bars = [ ];
        gaps = {
          inner = 0;
          outer = 0;
        };
        fonts = {
          names = [ "DejaVu Sans Mono" ];
          style = "Regular";
          size = 0.0;
        };
        modifier = "Mod4";
        terminal = terminal-emulator;
        menu = ''
          "${pkgs.rofi}/bin/rofi -dpi 0 -show drun -run-shell-command '{terminal} -e \\" {cmd}; read -n 1 -s\\"'"'';
        focus.followMouse = false;
        focus.newWindow = "urgent";
        startup = [
          {
            command = "${pkgs.dex}/bin/dex --autostart --environment i3";
            notification = false;
          }
          # https://github.com/nix-community/home-manager/issues/213#issuecomment-366962925
          {
            command = "${pkgs.systemd}/bin/systemctl --user restart polybar";
            always = true;
            notification = false;
          }
        ];
        colors = {
          # Nord theme
          focused = {
            border = colors.nord9;
            background = colors.nord9;
            text = "#ffffff";
            indicator = colors.nord9;
            childBorder = colors.nord9;
          };
          unfocused = {
            border = colors.nord0;
            background = "#1f222d";
            text = "#888888";
            indicator = "#1f222d";
            childBorder = colors.nord0;
          };
          focusedInactive = {
            border = colors.nord0;
            background = "#1f222d";
            text = "#888888";
            indicator = "#1f222d";
            childBorder = colors.nord0;
          };
          placeholder = {
            border = colors.nord0;
            background = "#1f222d";
            text = "#888888";
            indicator = "#1f222d";
            childBorder = colors.nord0;
          };
          urgent = {
            border = "#900000";
            background = "#900000";
            text = "#ffffff";
            indicator = "#900000";
            childBorder = "#900000";
          };
          background = "#242424";
        };
        keybindings =
          let mod = config.xsession.windowManager.i3.config.modifier;
          in lib.mkOptionDefault {
            "${mod}+1" = "workspace ${workspace1}";
            "${mod}+2" = "workspace ${workspace2}";
            "${mod}+3" = "workspace ${workspace3}";
            "${mod}+4" = "workspace ${workspace4}";
            "${mod}+5" = "workspace ${workspace5}";
            "${mod}+6" = "workspace ${workspace6}";
            "${mod}+7" = "workspace ${workspace7}";
            "${mod}+8" = "workspace ${workspace8}";
            "${mod}+9" = "workspace ${workspace9}";
            "${mod}+0" = "workspace ${workspace10}";
            "${mod}+Shift+1" =
              "move container to workspace ${workspace1}; workspace ${workspace1}";
            "${mod}+Shift+2" =
              "move container to workspace ${workspace2}; workspace ${workspace2}";
            "${mod}+Shift+3" =
              "move container to workspace ${workspace3}; workspace ${workspace3}";
            "${mod}+Shift+4" =
              "move container to workspace ${workspace4}; workspace ${workspace4}";
            "${mod}+Shift+5" =
              "move container to workspace ${workspace5}; workspace ${workspace5}";
            "${mod}+Shift+6" =
              "move container to workspace ${workspace6}; workspace ${workspace6}";
            "${mod}+Shift+7" =
              "move container to workspace ${workspace7}; workspace ${workspace7}";
            "${mod}+Shift+8" =
              "move container to workspace ${workspace8}; workspace ${workspace8}";
            "${mod}+Shift+9" =
              "move container to workspace ${workspace9}; workspace ${workspace9}";
            "${mod}+Shift+0" =
              "move container to workspace ${workspace10}; workspace ${workspace10}";

            # change focus (Vi keybindings)
            "${mod}+h" = "focus left";
            "${mod}+j" = "focus down";
            "${mod}+k" = "focus up";
            "${mod}+l" = "focus right";
            "${mod}+Shift+h" = "move left";
            "${mod}+Shift+j" = "move down";
            "${mod}+Shift+k" = "move up";
            "${mod}+Shift+l" = "move right";

            # split in horizontal orientation
            "${mod}+backslash" = "split h";
            "${mod}+Shift+backslash" = "split h";
            # split in vertical orientation
            "${mod}+minus" = "split v";
            "${mod}+Shift+minus" = "split v";

            # Toggle scratchpad
            "${mod}+numbersign" = "scratchpad show";
            # Move window to scratchpad
            "${mod}+Shift+numbersign" = "move scratchpad";

            # focus the parent container
            "${mod}+a" = "focus parent";
            # focus the child container
            "${mod}+Shift+a" = "focus child";
            "${mod}+apostrophe" = "focus child";

            # Move focus/workspace/window to different monitor
            "${mod}+at" = "focus output left";
            "${mod}+Shift+at" =
              "move container to output left; focus output left";
            "${mod}+Shift+Ctrl+at" = "move workspace to output left";
            "${mod}+slash" = "focus output right";
            "${mod}+Shift+slash" =
              "move container to output right; focus output right";
            "${mod}+Shift+Ctrl+slash" = "move workspace to output right";

            # Gaps mode
            "${mod}+g" = ''mode "${mode-gaps}"'';
          };
        modes = {
          resize = {
            "h" = "resize shrink width 20 px or 10 ppt";
            "j" = "resize grow height 20 px or 10 ppt";
            "k" = "resize shrink height 20 px or 10 ppt";
            "l" = "resize grow width 20 px or 10 ppt";
            "Shift+h" = "resize shrink width 200 px or 20 ppt";
            "Shift+j" = "resize grow height 200 px or 20 ppt";
            "Shift+k" = "resize shrink height 200 px or 20 ppt";
            "Shift+l" = "resize grow width 200 px or 20 ppt";
            "Return" = "mode default";
            "Escape" = "mode default";
          };
          "${mode-gaps}" = {
            "o" = ''mode "${mode-gaps-inner}"'';
            "i" = ''mode "${mode-gaps-inner}"'';
            "Return" = "mode default";
            "Escape" = "mode default";
          };
          "${mode-gaps-inner}" = {
            "plus" = "gaps inner current plus 5";
            "minus" = "gaps inner current minus 5";
            "asterisk" = "gaps inner current set 0";
            "Shift+plus" = "gaps inner all plus 5";
            "Shift+minus" = "gaps inner all minus 5";
            "Shift+asterisk" = "gaps inner all set 0";
            "Return" = "mode default";
            "Escape" = "mode default";
          };
          "${mode-gaps-outer}" = {
            "plus" = "gaps outer current plus 5";
            "minus" = "gaps outer current minus 5";
            "asterisk" = "gaps outer current set 0";
            "Shift+plus" = "gaps outer all plus 5";
            "Shift+minus" = "gaps outer all minus 5";
            "Shift+asterisk" = "gaps outer all set 0";
            "Return" = "mode default";
            "Escape" = "mode default";
          };
        };
        assigns = {
          "${workspace2}" = [{
            class = "^Firefox$";
            window_role = "(?i)^((?!dialog).)+$";
          }];
          "${workspace9}" = [{ class = "^Thunderbird$"; }];
          "${workspace10}" = [
            { class = "^TelegramDesktop$"; }
            { class = "^Slack$"; }
            { class = "^Skype$"; }
            { class = "^Signal$"; }
            { class = "^Ferdium$"; }
          ];
        };
        window.border = 0;
        window.hideEdgeBorders = "both";
        window.commands = let
          mkCommand = command: criteria: { inherit command criteria; };
          mkFloating = mkCommand "floating enable";
          mkSticky = mkCommand "sticky enable";
        in [
          {
            criteria = { class = ".*"; };
            command = "border pixel 0";
          }
          (mkFloating { class = "^emacs-everywhere$"; })
          (mkFloating { class = "^Tor Browser$"; })
          (mkFloating { class = "^gnome-calculator$"; })
          (mkFloating { class = "^feh$"; })
          (mkFloating { class = "^Sxiv$"; })
          (mkFloating {
            class = "^Thunderbird$";
            instance = "^Calendar$";
          })
          (mkFloating {
            class = "^Steam$";
            instance = "Steam Guard";
          })
          (mkFloating { class = "^(?i)zoom$"; })
          (mkFloating { class = "(?i)blueman-manager"; })
          (mkFloating {
            class = "^Steam$";
            title = "^Steam Guard";
          })
          (mkFloating { window_type = "dialog"; })
          (mkFloating { window_role = "pop-up"; })
          (mkFloating { window_role = "task_dialog"; })
          (mkFloating { window_role = "(?i)about"; })
          (mkFloating { window_role = "(?i)preferences"; })
          (mkSticky { title = "Picture-in-Picture"; })
          (mkSticky { title = "AlarmWindow"; })
        ];
      };
      extraConfig = ''
        popup_during_fullscreen leave_fullscreen
      '';
    };
  };

  systemd.user = {
    services = {
      mpris-proxy = {
        Unit = {
          Description = "Forward bluetooth media controls to MPRIS";
          After = [ "network.target" "sound.target" ];
        };
        Install.WantedBy = [ "default.target" ];
        Service.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
      };
      picom.Service.EnvironmentFile = "-${config.xdg.dataHome}/picom/env";
      xfsettingsd = {
        Unit = {
          Description = "xfsettingsd";
          After = [ "graphical-session-pre.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Install.WantedBy = [ "graphical-session.target" ];
        Service = {
          Environment = "PATH=${config.home.profileDirectory}/bin";
          ExecStart = "${pkgs.xfce.xfce4-settings}/bin/xfsettingsd";
          Restart = "on-abort";
        };
      };
      yubikey-touch-detector = {
        Unit = {
          Description =
            "A tool to detect when your YubiKey is waiting for a touch";
          After = [ "graphical-session-pre.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Install.WantedBy = [ "graphical-session.target" ];
        Service = {
          ExecStart =
            "${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector --libnotify";
          Restart = "on-abort";
        };
      };
    };
  };

  xdg = {
    enable = true;
    userDirs.enable = true;
    configFile = with config.xdg; {
      "bat/config".text = ''
        --theme="Nord"
        --italic-text=always
        --map-syntax='.ignore:Git Ignore'
      '';
      "chemacs/profiles.el".text = ''
        (("default" . ((user-emacs-directory . "${configHome}/my-emacs")))
         ("doom" . ((user-emacs-directory . "${configHome}/doom-emacs")
                    (env . (("DOOMDIR" . "${config.home.sessionVariables.DOOMDIR}")
                            ("DOOMLOCALDIR" . "${config.home.sessionVariables.DOOMLOCALDIR}"))))))
      '';
      "chemacs/profile".text = "doom";
      "curl/.curlrc".text = ''
        write-out "\n"
        silent
        dump-header /dev/stderr
      '';
      doom-emacs = {
        source = doomEmacsSource;
        onChange = "${pkgs.writeShellScript "doom-change" ''
          export DOOMDIR="${config.home.sessionVariables.DOOMDIR}"
          export DOOMLOCALDIR="${config.home.sessionVariables.DOOMLOCALDIR}"
          if [ ! -d "$DOOMLOCALDIR" ]; then
            ${configHome}/doom-emacs/bin/doom --force install
          else
            ${configHome}/doom-emacs/bin/doom --force clean
            ${configHome}/doom-emacs/bin/doom --force sync -u
          fi
        ''}";
      };
      "doom/config.el".text = ''
        ;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

        ;; Place your private configuration here! Remember, you do not need to run 'doom
        ;; sync' after modifying this file!

        ;; Some functionality uses this to identify you, e.g. GPG configuration, email
        ;; clients, file templates and snippets.
        (setq user-full-name "Xandor Schiefer"
              user-mail-address "me@xandor.co.za")

        ;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
        ;; are the three important ones:
        ;;
        ;; + `doom-font'
        ;; + `doom-variable-pitch-font'
        ;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
        ;;   presentations or streaming.
        ;;
        ;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
        ;; font string. You generally only need these two:
        (setq doom-font (font-spec :family "Iosevka Nerd Font" :size 12 :weight 'light)
              doom-variable-pitch-font (font-spec :family "Iosevka Aile" :size 13)
              doom-big-font (font-spec :family "Iosevka Nerd Font" :size 18 :weight 'light))

        ;; There are two ways to load a theme. Both assume the theme is installed and
        ;; available. You can either set `doom-theme' or manually load a theme with the
        ;; `load-theme' function. This is the default:
        (setq doom-theme 'doom-nord)

        ;; If you use `org' and don't want your org files in the default location below,
        ;; change `org-directory'. It must be set before org loads!
        (setq org-directory "~/Documents/notes"
              org-roam-directory "~/Documents/notes"
              org-agenda-files '("~/Documents/notes" "~/Documents/notes/daily"))

        ;; This determines the style of line numbers in effect. If set to `nil', line
        ;; numbers are disabled. For relative line numbers, set this to `relative'.
        (setq display-line-numbers-type 'relative)

        (setq projectile-project-search-path '(("~/Code/" . 2)))

        ;; Handle secrets with `pass`
        (require 'password-store)
        (setq auth-sources '(password-store))
        (setq auth-source-pass-filename "${config.programs.password-store.settings.PASSWORD_STORE_DIR}")

        ;; Here are some additional functions/macros that could help you configure Doom:
        ;;
        ;; - `load!' for loading external *.el files relative to this one
        ;; - `use-package!' for configuring packages
        ;; - `after!' for running code after a package has loaded
        ;; - `add-load-path!' for adding directories to the `load-path', relative to
        ;;   this file. Emacs searches the `load-path' when you load packages with
        ;;   `require' or `use-package'.
        ;; - `map!' for binding new keys
        ;;
        ;; To get information about any of these functions/macros, move the cursor over
        ;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
        ;; This will open documentation for it, including demos of how they are used.
        ;;
        ;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
        ;; they are implemented.


        (map! :leader
              :desc "Increase font size"
              "+" #'text-scale-adjust)
        (map! :leader
              :desc "Decrease font size"
              "-" #'text-scale-adjust)
        (map! :leader
              :desc "Reset font size"
              "0" #'text-scale-adjust)

        ;; Enable some more Evil keybindings for org-mode
        (after! evil-org
          (evil-org-set-key-theme '(navigation
                                    insert
                                    textobjects
                                    additional
                                    calendar
                                    shift
                                    todo
                                    heading)))

          (use-package! org-super-agenda
            :after org-agenda
            :init
            (require 'evil-org-agenda)
            (setq org-super-agenda-groups '((:name "Today"
                                                   :time-grid t
                                                   :scheduled today)
                                            (:name "Due today"
                                                   :deadline today)
                                            (:name "Important"
                                                   :priority "A")
                                            (:name "Overdue"
                                                   :deadline past)
                                            (:name "Due soon"
                                                   :deadline future)))
            :config
            ;; https://github.com/alphapapa/org-super-agenda/issues/50#issuecomment-817432643
            (setq org-super-agenda-header-map evil-org-agenda-mode-map)
            (org-super-agenda-mode))

          (add-to-list 'auto-mode-alist '("\\.mermaid\\'" . mermaid-mode))
          (setq mermaid-output-format ".svg")

          ;; Don't auto-resolve clocks, because all our org-roam files are also
          ;; agenda files, auto-resolution takes forever as org has to open each
          ;; of them.
          (setq org-clock-auto-clock-resolution nil)

          ;; Invalidate Projectile cache when using Magit to check out different commits
          ;; https://emacs.stackexchange.com/a/26272
          (defun run-projectile-invalidate-cache (&rest _args)
            ;; We ignore the args to `magit-checkout'.
            (projectile-invalidate-cache nil))
          (advice-add 'magit-checkout
                      :after #'run-projectile-invalidate-cache)
          (advice-add 'magit-branch-and-checkout ; This is `b c'.
                      :after #'run-projectile-invalidate-cache)

          ;; Don't use language servers to auto-format
          (setq +format-with-lsp nil)

          ;; LSP perf tweaks
          ;; https://emacs-lsp.github.io/lsp-mode/page/performance/
          (setq read-process-output-max (* 1024 1024)) ;; 1mb
          (setq lsp-idle-delay 0.500)
          (setq gc-cons-threshold 100000000) ;; 100mb

          ;; ts-ls bugfix, should be unnecessary for Emacs 29
          ;; https://github.com/emacs-lsp/lsp-mode/issues/2681#issuecomment-1214902146
          (advice-add 'json-parse-buffer :around
                      (lambda (orig &rest rest)
                        (while (re-search-forward "\\u0000" nil t)
                          (replace-match ""))
                        (apply orig rest)))

          (setq fancy-splash-image "${../backgrounds/doom.png}")
          ;; (add-to-list 'default-frame-alist '(alpha-background . 95))
        (setq lsp-eslint-server-command '("${pkgs.nodejs}/bin/node"
                                          "${pkgs.vscode-extensions.dbaeumer.vscode-eslint}/share/vscode/extensions/dbaeumer.vscode-eslint/server/out/eslintServer.js"
                                          "--stdio"))

        (setq lsp-nix-nil-server-path "${pkgs.nil}/bin/nil")

        ;; Disable invasive lsp-mode features
        (after! lsp-mode
          (setq lsp-enable-symbol-highlighting nil
                lsp-enable-suggest-server-download nil
                lsp-clients-typescript-prefer-use-project-ts-server t))
        (after! lsp-ui
          (setq lsp-ui-sideline-enable nil  ; no more useful than flycheck
                lsp-ui-doc-enable nil))     ; redundant with K

        ;; Debug Adapter Protocol
        (setq dap-firefox-debug-path "${pkgs.vscode-extensions.firefox-devtools.vscode-firefox-debug}/share/vscode/extensions/firefox-devtools.vscode-firefox-debug"
              dap-firefox-debug-program (list "${pkgs.nodejs}/bin/node" (concat dap-firefox-debug-path "/dist/extension.bundle.js"))
              dap-chrome-debug-path "${pkgs.vscodium}/lib/vscode/resources/app/extensions/ms-vscode.js-debug"
              dap-chrome-debug-program (list "${pkgs.nodejs}/bin/node" (concat dap-chrome-debug-path "/src/extension.js"))
              dap-node-debug-path dap-chrome-debug-path
              dap-node-debug-program dap-chrome-debug-program)
        (dap-mode 1)
        (dap-ui-mode 1)
        (dap-tooltip-mode 1)
        (tooltip-mode 1)
        (dap-ui-controls-mode 1)
        (require 'dap-firefox)
        (require 'dap-chrome)
        (require 'dap-node)

        ;; Emacs everywhere
        (after! emacs-everywhere
          (setq emacs-everywhere-frame-name-format "emacs-everywhere")

          ;; The modeline is not useful to me in the popup window. It looks much nicer
          ;; to hide it.
          (remove-hook 'emacs-everywhere-init-hooks #'hide-mode-line-mode)

          ;; Semi-center it over the target window, rather than at the cursor position
          ;; (which could be anywhere).
          (defadvice! center-emacs-everywhere-in-origin-window (frame window-info)
            :override #'emacs-everywhere-set-frame-position
            (cl-destructuring-bind (x y width height)
                (emacs-everywhere-window-geometry window-info)
              (set-frame-position frame
                                  (+ x (/ width 2) (- (/ width 2)))
                                  (+ y (/ height 2))))))
        (atomic-chrome-start-server)

        ;; Use Tree Sitter wherever we can
        (setq +tree-sitter-hl-enabled-modes t)
        ;; Don't try to download or build the binary, Nix already has it
        (setq tsc-dyn-get-from nil
              tsc-dyn-dir "${my-doom-emacs.emacs.pkgs.tsc}/share/emacs/site-lisp/elpa/${my-doom-emacs.emacs.pkgs.tsc.name}")
        ;; Nix has already built all the available grammars for us
        (setq tree-sitter-load-path '("${
          pkgs.runCommandLocal "tree-sitter-grammars-bundle" { } ''
            mkdir -p $out
            ${
              lib.concatStringsSep "\n" (lib.mapAttrsToList (name: src:
                "ln -s ${src}/parser $out/${
                  (builtins.replaceStrings [ "tree-sitter-" ] [ "" ] name)
                }.so") pkgs.tree-sitter.builtGrammars)
            };
          ''
        }"))

        (setq dash-docs-docsets-path "${config.xdg.dataFile.docsets.source}")
        (set-docsets! 'js2-mode "JavaScript" "NodeJS")
        (set-docsets! 'rjsx-mode "JavaScript" "React")
        (set-docsets! 'typescript-mode "JavaScript" "NodeJS")
        (set-docsets! 'typescript-tsx-mode "JavaScript" "React")
      '';
      "doom/init.el" = {
        text = ''
          ;;; init.el -*- lexical-binding: t; -*-

          ;; This file controls what Doom modules are enabled and what order they load
          ;; in. Remember to run 'doom sync' after modifying it!

          ;; NOTE Press 'SPC h d h' (or 'C-h d h' for non-vim users) to access Doom's
          ;;      documentation. There you'll find a "Module Index" link where you'll find
          ;;      a comprehensive list of Doom's modules and what flags they support.

          ;; NOTE Move your cursor over a module's name (or its flags) and press 'K' (or
          ;;      'C-c c k' for non-vim users) to view its documentation. This works on
          ;;      flags as well (those symbols that start with a plus).
          ;;
          ;;      Alternatively, press 'gd' (or 'C-c c d') on a module to browse its
          ;;      directory (for easy access to its source code).

          (doom! :input
                 ;;chinese
                 ;;japanese
                 ;;layout            ; auie,ctsrnm is the superior home row

                 :completion
                 company           ; the ultimate code completion backend
                 ;;helm              ; the *other* search engine for love and life
                 ;;ido               ; the other *other* search engine...
                 ivy               ; a search engine for love and life

                 :ui
                 ;;deft              ; notational velocity for Emacs
                 doom              ; what makes DOOM look the way it does
                 doom-dashboard    ; a nifty splash screen for Emacs
                 doom-quit         ; DOOM quit-message prompts when you quit Emacs
                 ;;(emoji +unicode)  ; 🙂
                 hl-todo           ; highlight TODO/FIXME/NOTE/DEPRECATED/HACK/REVIEW
                 ;;hydra
                 indent-guides     ; highlighted indent columns
                 ligatures         ; ligatures and symbols to make your code pretty again
                 minimap           ; show a map of the code on the side
                 modeline          ; snazzy, Atom-inspired modeline, plus API
                 nav-flash         ; blink cursor line after big motions
                 ;;neotree           ; a project drawer, like NERDTree for vim
                 ophints           ; highlight the region an operation acts on
                 (popup +defaults)   ; tame sudden yet inevitable temporary windows
                 ;;tabs              ; a tab bar for Emacs
                 (treemacs +lsp)          ; a project drawer, like neotree but cooler
                 unicode           ; extended unicode support for various languages
                 vc-gutter         ; vcs diff in the fringe
                 vi-tilde-fringe   ; fringe tildes to mark beyond EOB
                 ;;window-select     ; visually switch windows
                 workspaces        ; tab emulation, persistence & separate workspaces
                 ;;zen               ; distraction-free coding or writing

                 :editor
                 (evil +everywhere); come to the dark side, we have cookies
                 file-templates    ; auto-snippets for empty files
                 fold              ; (nigh) universal code folding
                 (format +onsave)  ; automated prettiness
                 ;;god               ; run Emacs commands without modifier keys
                 ;;lispy             ; vim for lisp, for people who don't like vim
                 multiple-cursors  ; editing in many places at once
                 ;;objed             ; text object editing for the innocent
                 ;;parinfer          ; turn lisp into python, sort of
                 ;;rotate-text       ; cycle region at point between text candidates
                 snippets          ; my elves. They type so I don't have to
                 ;;word-wrap         ; soft wrapping with language-aware indent

                 :emacs
                 dired             ; making dired pretty [functional]
                 electric          ; smarter, keyword-based electric-indent
                 ;;ibuffer         ; interactive buffer management
                 undo              ; persistent, smarter undo for your inevitable mistakes
                 vc                ; version-control and Emacs, sitting in a tree

                 :term
                 ;;eshell            ; the elisp shell that works everywhere
                 ;;shell             ; simple shell REPL for Emacs
                 ;;term              ; basic terminal emulator for Emacs
                 vterm             ; the best terminal emulation in Emacs

                 :checkers
                 (syntax +childframe) ; tasing you for every semicolon you forget
                 (spell +enchant +flyspell +everywhere) ; tasing you for misspelling mispelling
                 grammar           ; tasing grammar mistake every you make

                 :tools
                 ;;ansible
                 (debugger +lsp)          ; FIXME stepping through code, to help you add bugs
                 direnv
                 (docker +lsp)
                 editorconfig      ; let someone else argue about tabs vs spaces
                 ;;ein               ; tame Jupyter notebooks with emacs
                 (eval +overlay)     ; run code, run (also, repls)
                 ;;gist              ; interacting with github gists
                 lookup              ; navigate your code and its documentation
                 (lsp +peek)
                 (magit +forge)             ; a git porcelain for Emacs
                 ;;make              ; run make tasks from Emacs
                 ;;pass              ; password manager for nerds
                 ;;pdf               ; pdf enhancements
                 ;;prodigy           ; FIXME managing external services & code builders
                 rgb               ; creating color strings
                 ;;taskrunner        ; taskrunner for all your projects
                 ;;terraform         ; infrastructure as code
                 ;;tmux              ; an API for interacting with tmux
                 ;;upload            ; map local to remote projects via ssh/ftp
                 tree-sitter       ; better syntax highlighting and structural text objects

                 :os
                 (:if IS-MAC macos)  ; improve compatibility with macOS
                 ;;tty               ; improve the terminal Emacs experience

                 :lang
                 ;;agda              ; types of types of types of types...
                 (beancount +lsp)    ; Mind the GAAP
                 ;;cc                ; C/C++/Obj-C madness
                 ;;clojure           ; java with a lisp
                 ;;common-lisp       ; if you've seen one lisp, you've seen them all
                 ;;coq               ; proofs-as-programs
                 ;;crystal           ; ruby at the speed of c
                 ;;csharp            ; unity, .NET, and mono shenanigans
                 ;;data              ; config/data formats
                 ;;(dart +flutter)   ; paint ui and not much else
                 ;;elixir            ; erlang done right
                 ;;elm               ; care for a cup of TEA?
                 emacs-lisp        ; drown in parentheses
                 ;;erlang            ; an elegant language for a more civilized age
                 ;;ess               ; emacs speaks statistics
                 ;;faust             ; dsp, but you get to keep your soul
                 ;;fsharp            ; ML stands for Microsoft's Language
                 ;;fstar             ; (dependent) types and (monadic) effects and Z3
                 ;;gdscript          ; the language you waited for
                 ;;(go +lsp)         ; the hipster dialect
                 (haskell +lsp +tree-sitter)  ; a language that's lazier than I am
                 ;;hy                ; readability of scheme w/ speed of python
                 ;;idris             ; a language you can depend on
                 (json +lsp +tree-sitter)              ; At least it ain't XML
                 ;;(java +meghanada) ; the poster child for carpal tunnel syndrome
                 (javascript +lsp +tree-sitter)        ; all(hope(abandon(ye(who(enter(here))))))
                 ;;julia             ; a better, faster MATLAB
                 ;;kotlin            ; a better, slicker Java(Script)
                 ;;latex             ; writing papers in Emacs has never been so fun
                 ;;lean
                 ;;factor
                 ;;ledger            ; an accounting system in Emacs
                 ;;lua               ; one-based indices? one-based indices
                 markdown          ; writing docs for people to ignore
                 ;;nim               ; python + lisp at the speed of c
                 (nix +tree-sitter)               ; I hereby declare "nix geht mehr!"
                 ;;ocaml             ; an objective camel
                 (org               ; organize your plain life in plain text
                  +pretty
                  +roam2)
                 ;;php               ; perl's insecure younger brother
                 ;;plantuml          ; diagrams for confusing people more
                 ;;purescript        ; javascript, but functional
                 (python +lsp +tree-sitter)            ; beautiful is better than ugly
                 ;;qt                ; the 'cutest' gui framework ever
                 ;;racket            ; a DSL for DSLs
                 ;;raku              ; the artist formerly known as perl6
                 ;;rest              ; Emacs as a REST client
                 ;;rst               ; ReST in peace
                 ;;(ruby +rails)     ; 1.step {|i| p "Ruby is #{i.even? ? 'love' : 'life'}"}
                 ;;rust              ; Fe2O3.unwrap().unwrap().unwrap().unwrap()
                 ;;scala             ; java, but good
                 ;;scheme            ; a fully conniving family of lisps
                 (sh +fish +lsp +tree-sitter)                ; she sells {ba,z,fi}sh shells on the C xor
                 ;;sml
                 ;;solidity          ; do you need a blockchain? No.
                 ;;swift             ; who asked for emoji variables?
                 ;;terra             ; Earth and Moon in alignment for performance.
                 (web +lsp +tree-sitter)              ; the tubes
                 (yaml +lsp +tree-sitter)              ; JSON, but readable

                 :email
                 ;;(mu4e +gmail)
                 ;;notmuch
                 ;;(wanderlust +gmail)

                 :app
                 ;;calendar
                 ;;emms
                 everywhere        ; *leave* Emacs!? You must be joking
                 ;;irc               ; how neckbeards socialize
                 ;;(rss +org)        ; emacs as an RSS reader
                 ;;twitter           ; twitter client https://twitter.com/vnought

                 :config
                 ;;literate
                 (default +bindings +smartparens))
        '';
        onChange = "${pkgs.writeShellScript "doom-config-init-change" ''
          export DOOMDIR="${config.home.sessionVariables.DOOMDIR}"
          export DOOMLOCALDIR="${config.home.sessionVariables.DOOMLOCALDIR}"
          ${configHome}/doom-emacs/bin/doom --force sync
        ''}";
      };
      "doom/packages.el" = {
        text = ''
          ;; -*- no-byte-compile: t; -*-
          ;;; $DOOMDIR/packages.el

          ;; To install a package with Doom you must declare them here and run 'doom sync'
          ;; on the command line, then restart Emacs for the changes to take effect -- or
          ;; use 'M-x doom/reload'.


          ;; To install SOME-PACKAGE from MELPA, ELPA or emacsmirror:
          ;(package! some-package)

          ;; To install a package directly from a remote git repo, you must specify a
          ;; `:recipe'. You'll find documentation on what `:recipe' accepts here:
          ;; https://github.com/raxod502/straight.el#the-recipe-format
          ;(package! another-package
          ;  :recipe (:host github :repo "username/repo"))

          ;; If the package you are trying to install does not contain a PACKAGENAME.el
          ;; file, or is located in a subdirectory of the repo, you'll need to specify
          ;; `:files' in the `:recipe':
          ;(package! this-package
          ;  :recipe (:host github :repo "username/repo"
          ;           :files ("some-file.el" "src/lisp/*.el")))

          ;; If you'd like to disable a package included with Doom, you can do so here
          ;; with the `:disable' property:
          ;(package! builtin-package :disable t)

          ;; You can override the recipe of a built in package without having to specify
          ;; all the properties for `:recipe'. These will inherit the rest of its recipe
          ;; from Doom or MELPA/ELPA/Emacsmirror:
          ;(package! builtin-package :recipe (:nonrecursive t))
          ;(package! builtin-package-2 :recipe (:repo "myfork/package"))

          ;; Specify a `:branch' to install a package from a particular branch or tag.
          ;; This is required for some packages whose default branch isn't 'master' (which
          ;; our package manager can't deal with; see raxod502/straight.el#279)
          ;(package! builtin-package :recipe (:branch "develop"))

          ;; Use `:pin' to specify a particular commit to install.
          ;(package! builtin-package :pin "1a2b3c4d5e")


          ;; Doom's packages are pinned to a specific commit and updated from release to
          ;; release. The `unpin!' macro allows you to unpin single packages...
          ;(unpin! pinned-package)
          ;; ...or multiple packages
          ;(unpin! pinned-package another-pinned-package)
          ;; ...Or *all* packages (NOT RECOMMENDED; will likely break things)
          ;(unpin! t)

          (package! org-super-agenda)

          (package! mermaid-mode)

          (package! csv-mode)

          (package! atomic-chrome)

          ;; `lsp-mode` is lagging behind `vscode-eslint`
          ;; https://github.com/emacs-lsp/lsp-mode/issues/4091
          (package! lsp-mode :built-in t)
        '';
        onChange = "${pkgs.writeShellScript "doom-config-packages-change" ''
          export DOOMDIR="${config.home.sessionVariables.DOOMDIR}"
          export DOOMLOCALDIR="${config.home.sessionVariables.DOOMLOCALDIR}"
          ${configHome}/doom-emacs/bin/doom --force sync
        ''}";
      };
      emacs.source = builtins.fetchGit {
        url = "https://github.com/plexus/chemacs2";
        rev = "30a20dbc2799e4ab2f8c509fdadcd90aa9845b5c";
      };
      "flameshot/flameshot.ini" = {
        text = ''
          [General]
          checkForUpdates=false
          contrastOpacity=127
          contrastUiColor=#4476ff
          copyAndCloseAfterUpload=true
          copyPathAfterSave=true
          disabledTrayIcon=true
          drawColor=#1e6cc5
          drawThickness=2
          saveAfterCopy=true
          ; saveAfterCopyPath=/home/zeorin/Screenshots
          savePath=/home/zeorin/Screenshots
          savePathFixed=false
          showHelp=false
          showStartupLaunchMessage=true
          startupLaunch=false
          uiColor=#003396

          [Shortcuts]
          TYPE_ARROW=A
          TYPE_CIRCLE=C
          TYPE_CIRCLECOUNT=
          TYPE_COMMIT_CURRENT_TOOL=Ctrl+Return
          TYPE_COPY=Ctrl+C
          TYPE_DRAWER=D
          TYPE_EXIT=Ctrl+Q
          TYPE_IMAGEUPLOADER=Return
          TYPE_MARKER=M
          TYPE_MOVESELECTION=Ctrl+M
          TYPE_MOVE_DOWN=Down
          TYPE_MOVE_LEFT=Left
          TYPE_MOVE_RIGHT=Right
          TYPE_MOVE_UP=Up
          TYPE_OPEN_APP=Ctrl+O
          TYPE_PENCIL=P
          TYPE_PIN=
          TYPE_PIXELATE=B
          TYPE_RECTANGLE=R
          TYPE_REDO=Ctrl+Shift+Z
          TYPE_RESIZE_DOWN=Shift+Down
          TYPE_RESIZE_LEFT=Shift+Left
          TYPE_RESIZE_RIGHT=Shift+Right
          TYPE_RESIZE_UP=Shift+Up
          TYPE_SAVE=Ctrl+S
          TYPE_SELECTION=S
          TYPE_SELECTIONINDICATOR=
          TYPE_SELECT_ALL=Ctrl+A
          TYPE_TEXT=T
          TYPE_TOGGLE_PANEL=Space
          TYPE_UNDO=Ctrl+Z
        '';
        onChange = "${pkgs.writeShellScript "restart flameshot.service" ''
          ${pkgs.systemd}/bin/systemctl --user restart flameshot.service
        ''}";
      };
      "npm/npmrc".text = ''
        init-author-name=Xandor Schiefer
        init-author-email=me@xandor.co.za
        init-version=0.0.0
        init-license=LGPL-3.0
        prefix=${dataHome}/npm
        cache=${cacheHome}/npm
      '';
      "picom/env-grayscale".text = ''
        ARG_0="--glx-fshader-win"
        ARG_1="
          uniform sampler2D tex;
          uniform float opacity;
          void main() {
              vec4 color = texture2D(tex, gl_TexCoord[0].xy);
              gl_FragColor = vec4(
                  vec3(0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b) * opacity,
                  color.a * opacity);
          }
        "
      '';
      "readline/inputrc".text = ''
        $include /etc/inputrc

        # Use VI keybindings for any program that uses GNU readline
        set editing-mode vi

        # Show all completions as soon as tab is pressed, even if there's more than one.
        set show-all-if-ambiguous on
        # List completions immediately instead of ringing bell first
        set show-all-if-unmodified on

        # Ignore case
        set completion-ignore-case on
        # Color files by types
        # Note that this may cause completion text blink in some terminals (e.g. xterm).
        set colored-stats on
        # Mark symlinked directories
        set mark-symlinked-directories on
        # Color the common prefix
        set colored-completion-prefix on
        # Color the common prefix in menu-complete
        set menu-complete-display-prefix on

        # Don’t print ^C
        set echo-control-characters off

        set show-mode-in-prompt on
        $if term=linux
          set vi-ins-mode-string \1\e[?0c\2
          set vi-cmd-mode-string \1\e[?8c\2
        $else
          set vi-ins-mode-string \1\e[6 q\2
          set vi-cmd-mode-string \1\e[2 q\2
        $endif

        $if mode=vi
          # Keymaps for when we're in command mode
          set keymap vi-command
            "gg": beginning-of-history
            "G": end-of-history
            "\e[A": history-search-backward
            "\e[B": history-search-forward
            j: history-search-forward
            k: history-search-backward

          # Keymaps for when we're in insert mode
          set keymap vi-insert
            "\C-w": backward-kill-word
            "\e[A": history-search-backward
            "\e[B": history-search-forward
            "\C-p": history-search-backward
            "\C-n": history-search-forward
        $endif
      '';
      "todo/config".text = ''
        export TODO_DIR="${userDirs.documents}/todo"
        export TODO_FILE="$TODO_DIR/todo.txt"
        export DONE_FILE="$TODO_DIR/done.txt"
        export REPORT_FILE="$TODO_DIR/report.txt"
        export PRI_A=$YELLOW        # color for A priority
        export PRI_B=$GREEN         # color for B priority
        export PRI_C=$LIGHT_BLUE    # color for C priority
        export PRI_D=...            # define your own
        export PRI_X=$WHITE         # color unless explicitly defined
        export COLOR_DONE=$LIGHT_GREY
        export COLOR_PROJECT=$RED
        export COLOR_CONTEXT=$RED
        export TODOTXT_DEFAULT_ACTION=ls
      '';
      "tridactyl/tridactylrc".text = ''
        " Reset all settings
        sanitize tridactyllocal tridactylsync

        """"""""""""""""""
        " Key bindings
        """"""""""""""""""

        " Take a note in org-roamm
        bind n js document.location.href = 'org-protocol://roam-ref?template=r&ref=' + encodeURIComponent(location.href) + '&title=' + encodeURIComponent(document.title) + '&body=' + encodeURIComponent(window.getSelection())

        " Don't lose windows on :qall https://github.com/tridactyl/tridactyl/issues/350
        alias qall !s ${pkgs.procps}/bin/pkill firefox

        " Comment toggler for Reddit, Hacker News and Lobste.rs
        bind ;c hint -Jc [class*="expand"],[class="togg"],[class="comment_folder"]

        " GitHub pull request checkout command to clipboard (only works if you're a collaborator or above)
        bind yp composite js document.getElementById("clone-help-step-1").textContent.replace("git checkout -b", "git checkout -B").replace("git pull ", "git fetch ") + "git reset --hard " + document.getElementById("clone-help-step-1").textContent.split(" ")[3].replace("-","/") | yank

        " Git{Hub,Lab} git clone via SSH yank
        bind yg composite js "${pkgs.git}/bin/git clone " + document.location.href.replace(/https?:\/\//,"git@").replace("/",":").replace(/$/,".git") | clipboard yank

        " As above but execute it and open terminal in folder
        bind ,g js let uri = document.location.href.replace(/https?:\/\//,"git@").replace("/",":").replace(/$/,".git"); tri.native.run("cd ~/projects; ${pkgs.git}/bin/git clone " + uri + "; cd \"$(${pkgs.coreutils}/bin/basename \"" + uri + "\" .git)\"; ${terminal-emulator}")

        " Handy multiwindow/multitasking binds
        bind gd tabdetach
        bind gD composite tabduplicate | tabdetach
        bind T composite tabduplicate

        " Override some FF defaults to equivalent Tridactyl command line
        bind <C-t> fillcmdline tabopen
        bind <C-l> fillcmdline open
        bind <C-n> fillcmdline winopen
        bind <CS-p> fillcmdline winopen -private

        " make D take you to the left after closing a tab
        bind D composite tabprev; tabclose #

        " Stupid workaround to let hint -; be used with composite which steals semi-colons
        alias hint_focus hint -;

        " Open right click menu on links
        bind ;C composite hint_focus; !s ${pkgs.xdotool}/bin/xdotool key Menu

        " The default is unintuitive
        bind J tabnext
        bind K tabprev

        " Emulate arrow keys in insert mode!
        bind --mode=insert <C-h> !s ${pkgs.xdotool}/bin/xdotool key Left
        bind --mode=insert <C-j> !s ${pkgs.xdotool}/bin/xdotool key Down
        bind --mode=insert <C-k> !s ${pkgs.xdotool}/bin/xdotool key Up
        bind --mode=insert <C-l> !s ${pkgs.xdotool}/bin/xdotool key Right

        " Like DOOM Emacs
        bind --mode=ex <C-j> ex.next_completion
        bind --mode=ex <C-k> ex.prev_completion
        bind --mode=ex <C-p> ex.prev_history
        bind --mode=ex <C-n> ex.next_history


        """"""""""""""""""
        " Appearance
        """"""""""""""""""

        " Don’t show modeindicator
        set modeindicator false

        colorscheme base16-nord

        """"""""""""""""""
        " Misc settings
        """"""""""""""""""

        " I’m a smooth operator
        set smoothscroll true

        " Sane hinting mode
        set hintfiltermode vimperator-reflow
        " I use Programmer Dvorak
        set hintchars dhtnaoeuifgcrl',.pybm;qjkx

        " Defaults to 300ms
        set hintdelay 100

        " Don't autofocus!
        set allowautofocus false

        " Disable Tridactyl on certain websites
        ${lib.strings.concatMapStrings (url: ''
          blacklistadd ${url}
          seturl ${url} allowautofocus true
        '') [
          "monkeytype\\.com"
          "codepen\\.io"
          "codesandbox\\.io"
          "github\\.dev"
          "typescriptlang\\.org/play"
        ]}
      '';
      "tridactyl/themes".source = pkgs.symlinkJoin {
        name = "tridactyl-themes";
        paths = [
          (builtins.fetchGit "https://github.com/tridactyl/base16-tridactyl")
          (pkgs.writeTextDir "zeorin.css" ''
            /* Same as default theme, but move the tridactyl console to the top */
            .TridactylOwnNamespace body {
                top: 0;
            }

            #command-line-holder {
                order: 1;
            }

            #completions {
                order: 2;
                border-top: unset;
                border-bottom: var(--tridactyl-cmplt-border-top);
            }

            #cmdline_iframe {
                bottom: unset;
                top: 0% !important;
            }
          '')
        ];
      };
        }
      '';
      "wget/wgetrc".text = ''
        hsts-file = ${cacheHome}/wget-hsts
      '';
      "X11/xresources".text = ''
        Xft.autohint: 0
        Xft.lcdfilter: lcddefault
        Xft.hintstyle: hintslight
        Xft.hinting: 1
        Xft.antialias: 1
        Xft.rgba: rgb
        Xft.dpi: 96

        ! Nord
        ! https://github.com/arcticicestudio/nord-xresources/blob/develop/src/nord

        *.foreground:   ${colors.nord4}
        *.background:   ${colors.nord0}
        *.cursorColor:  ${colors.nord4}
        *fading: 35
        *fadeColor: ${colors.nord3}

        *.color0: ${colors.nord1}
        *.color1: ${colors.nord11}
        *.color2: ${colors.nord14}
        *.color3: ${colors.nord13}
        *.color4: ${colors.nord9}
        *.color5: ${colors.nord15}
        *.color6: ${colors.nord8}
        *.color7: ${colors.nord5}
        *.color8: ${colors.nord3}
        *.color9: ${colors.nord11}
        *.color10: ${colors.nord14}
        *.color11: ${colors.nord13}
        *.color12: ${colors.nord9}
        *.color13: ${colors.nord15}
        *.color14: ${colors.nord7}
        *.color15: ${colors.nord6}
      '';
    };
    dataFile = with config.xdg; {
      "dark-mode.d/gtk-theme.sh".source =
        pkgs.writeShellScript "set-dark-theme.sh" ''
          ${pkgs.xfce.xfconf}/bin/xfconf-query --create --type string -c xsettings -p /Net/ThemeName -s "Nordic"
          ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
          ${pkgs.dconf}/bin/dconf write /org/freedesktop/appearance/color-scheme "'prefer-dark'"
        '';
      "light-mode.d/gtk-theme.sh".source =
        pkgs.writeShellScript "set-light-theme.sh" ''
          ${pkgs.xfce.xfconf}/bin/xfconf-query --create --type string -c xsettings -p /Net/ThemeName -s "Nordic-Polar"
          ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'prefer-light'"
          ${pkgs.dconf}/bin/dconf write /org/freedesktop/appearance/color-scheme "'prefer-light'"
        '';
      docsets.source = pkgs.symlinkJoin {
        name = "docsets";
        paths =
          # https://kapeli.com/dash#docsets
          map ({ name, sha256 }:
            pkgs.fetchzip {
              url = "https://kapeli.com/feeds/${name}.tgz";
              inherit sha256;
              stripRoot = false;
            }) [
              {
                name = "CSS";
                sha256 = "sha256-1FWZWKfDh4FLlF1EPIPpuXCkQYHRbMUSBS2P7KeNI0M=";
              }
              {
                name = "Docker";
                sha256 = "sha256-wyQagar+0VG72CX46xdW1tSiBcK1svtTrMUn1STpkks=";
              }
              {
                name = "Emacs_Lisp";
                sha256 = "sha256-GxGsT3xSvbjFNacwsew4xJk8rmv3kXvuEnCQeF8QFLY=";
              }
              {
                name = "Emmet";
                sha256 = "sha256-bTn7dJJ4fc+e4OzaWj4z0eeAZ7+wlutM3c2JTKU34QU=";
              }
              {
                name = "Express";
                sha256 = "sha256-E7+35AHVEG/wLyqRr7W+xbmdt0+n3VGm4wp57REPuhM=";
              }
              {
                name = "ExtJS";
                sha256 = "sha256-l8drgOXanSk1V8p5eoUCt8WInyIGfFH3XQE7AOYCcYs=";
              }
              {
                name = "Font_Awesome";
                sha256 = "sha256-pQi01pAmaJLaAIG4EdVerncVdAzTDmviUNVr81yNh9c=";
              }
              {
                name = "Haskell";
                sha256 = "sha256-ZSUWwrhqIT6T/aIL1gka64g0a2G4seuI8kfPBoSbaXA=";
              }
              {
                name = "HTML";
                sha256 = "sha256-vyQSffeLsNkdE2iqsvqmXpdc61KuXjrOtpAvjYbRxJc=";
              }
              {
                name = "JavaScript";
                sha256 = "sha256-40vNxbSmmUHZM04N1f08Ni39wdfTxkDXfKZsy2d24kc=";
              }
              {
                name = "Lo-Dash";
                sha256 = "sha256-irVO2nDTbqlLVBaqkTR5MfxHyuoDQda3dfXs64bcqS8=";
              }
              {
                name = "Markdown";
                sha256 = "sha256-WRjWe1frF9Ys68a1jVJPqZkzEWQNr5OGaHnWbBijRGc=";
              }
              {
                name = "MySQL";
                sha256 = "sha256-BrmCvM019s5tJjcmGNMG/JayJJAyQ74s1fJb6M3y53g=";
              }
              {
                name = "Nginx";
                sha256 = "sha256-7/LueWbyTAvwZa1wgLeXPtOsMxuiJTshN/dnBQIIDZ0=";
              }
              {
                name = "NodeJS";
                sha256 = "sha256-EzmYq3rK+9dfDN8tSmAg98lO3yN5iGo121N27BmmXiQ=";
              }
              {
                name = "PostgreSQL";
                sha256 = "sha256-gnTHNm3CCFwMHRKPwWCFbOKqfmjs3Nm0sBBIBNiaG8U=";
              }
              {
                name = "Python_3";
                sha256 = "sha256-mvnNfnhkXUh//8/3oZOS5x9M9llvkb661FteeH5oG0s=";
              }
              {
                name = "React";
                sha256 = "sha256-oGSms/Bi07bee19Lq8f/+2cAfb0/0D+c1YKErGZe4wM";
              }
            ];
      };
    };
    desktopEntries = {
      editor-protocol = {
        name = "editor protocol";
        exec = "${
            (pkgs.stdenv.mkDerivation rec {
              pname = "open-editor.sh";
              version = "2.10.2";
              src = pkgs.fetchFromGitHub {
                owner = "nette";
                repo = "tracy";
                rev = "v${version}";
                sha256 = "sha256-4bif5m7q0R8TGD6M0kYu8Dfx0uoq6RFW+UE9OQRr6a0=";
                sparseCheckout =
                  [ "tools/open-in-editor/linux/open-editor.sh" ];
              };
              dontConfigure = true;
              dontBuild = true;
              patchPhase = ''
                substituteInPlace tools/open-in-editor/linux/open-editor.sh \
                  --replace "#editor='emacs" "editor='${my-doom-emacs}/bin/emacsclient"

                chmod +x tools/open-in-editor/linux/open-editor.sh
              '';
              installPhase = ''
                bindir="$out/bin"
                install -d "$bindir"
                install tools/open-in-editor/linux/open-editor.sh "$bindir"
              '';
              enableParallelBuilding = true;
            })
          }/bin/open-editor.sh %u";
        icon = "emacs";
        type = "Application";
        terminal = false;
        categories = [ "System" ];
        mimeType = [ "x-scheme-handler/editor" ];
        noDisplay = true;
      };
      org-protocol = {
        name = "org-protocol";
        exec = ''
          ${my-doom-emacs}/bin/emacsclient --create-frame --alternate-editor="" %u'';
        icon = "emacs";
        type = "Application";
        terminal = false;
        categories = [ "System" ];
        mimeType = [ "x-scheme-handler/org-protocol" ];
        noDisplay = true;
      };
      my-emacs = {
        name = "My Emacs";
        exec = "${pkgs.emacs-gtk}/bin/emacs --with-profile default";
        icon = "emacs";
        type = "Application";
        terminal = false;
        categories = [ "System" ];
      };
    };
  };

  home.file = with config.xdg; {
    ".editrc".text = ''
      bind -v
    '';
    ".ghci".text = ''
      :set prompt      "\ESC[3;92m%s \ESC[0;37mλ  \ESC[m"
      :set prompt-cont "\ESC[0;90m%s \ESC[0;92m│  \ESC[m"
    '';
    ".haskeline".text = ''
      editMode: Vi
    '';
    ".mozilla/native-messaging-hosts/tridactyl.json".source =
      "${pkgs.tridactyl-native}/lib/mozilla/native-messaging-hosts/tridactyl.json";
    ".my.cnf".text = ''
      [client]
      user = root
      password
      no-beep
      sigint-ignore
      auto-vertical-output
      i-am-a-dummy
      auto-rehash
      pager = "${pkgs.ccze}/bin/ccze -A | ${pkgs.less}/bin/less -RSFXin"
      prompt="\n[\d] "
    '';
    ".xprofile".text = ''
      # Set up Xresources
      ${pkgs.xorg.xrdb}/bin/xrdb -load ${configHome}/X11/xresources

      # Polkit agent
      ${pkgs.lxqt.lxqt-policykit}/bin/lxqt-policykit-agent &
    '';
  };

  gtk = {
    theme = {
      package = pkgs.nordic;
      name = "Nordic-Polar";
    };
    iconTheme = {
      package = pkgs.la-capitaine-icon-theme;
      name = "La Capitaine";
    };
  };

  qt = {
    enable = true;
    platformTheme = "gtk";
  };

  fonts.fontconfig.enable = true;

  nixpkgs.config = {
    allowUnfree = true;
    joypixels.acceptLicense = true;
    packageOverrides = pkgs: {
      nur = import (builtins.fetchTarball
        "https://github.com/nix-community/NUR/archive/master.tar.gz") {
          inherit pkgs;
        };
    };
  };

  home.packages = with pkgs;
    [
      my-doom-emacs
      (writeShellScriptBin "edit.sh" ''
        if [ -n "$INSIDE_EMACS" ]; then
          ${my-doom-emacs}/bin/emacsclient --no-wait --quiet "$@"
        elif [ "$SSH_TTY$DISPLAY" = "''${DISPLAY#*:[1-9][0-9]}" ]; then
          # If we're not connected via SSH and the DISPLAY is less than 10
          ${my-doom-emacs}/bin/emacsclient --no-wait --create-frame --alternate-editor="" --quiet "$@"
        else
          ${my-doom-emacs}/bin/emacsclient --no-wait --tty --alternate-editor="" --quiet "$@"
        fi
      '')
      (aspellWithDicts (dicts: with dicts; [ en en-computers en-science ]))
      (hunspellWithDicts (with hunspellDicts; [ en_GB-large ]))
      (nuspellWithDicts (with hunspellDicts; [ en_GB-large ]))
      webcamoid
      libnotify
      file
      tree
      xsel
      xclip
      curl
      httpie
      xdg-user-dirs
      # https://github.com/NixOS/nixpkgs/issues/189567
      # wineWowPackages.stable
      (import (builtins.fetchTarball {
        url =
          "https://github.com/NixOS/nixpkgs/archive/7342cdc70156522050ce813386f6e159ca749d82.tar.gz";
      }) { }).wineWowPackages.stable
      winetricks
      protontricks
      protonup
      (writeShellScriptBin "nix-index-update" ''
        # https://github.com/Mic92/nix-index-database#ad-hoc-download
        filename="index-$(uname -m)-$(uname | tr A-Z a-z)"
        mkdir -p ~/.cache/nix-index && cd ~/.cache/nix-index
        # -N will only download a new version if there is an update.
        wget -q -N https://github.com/Mic92/nix-index-database/releases/latest/download/$filename
        ln -f $filename files
      '')
      capitaine-cursors
      la-capitaine-icon-theme
      nordic
      zafiro-icons
      gtk_engines
      gtk-engine-murrine
      wget
      wireshark
      websocat
      vim
      universal-ctags
      zip
      unzip
      numlockx
      filezilla
      silver-searcher
      ripgrep
      fd
      xorg.xkill
      bc
      feh
      lxappearance
      xorg.xcursorthemes
      protonvpn-gui
      protonvpn-cli
      thunderbird
      neomutt
      isync
      zathura
      sigil
      (calibre.overrideAttrs (oldAttrs: {
        buildInputs = oldAttrs.buildInputs
          ++ (with python3Packages; [ pycryptodome ]);
      }))
      gnome.gnome-calculator
      gnome.file-roller
      yt-dlp
      screenkey
      slop
      system-config-printer
      gnucash
      xournalpp
      transmission-gtk
      mpv
      weechat
      yubikey-manager
      yubikey-manager-qt
      yubikey-personalization
      yubikey-personalization-gui
      yubioath-desktop
      pcmanfm
      lxmenu-data
      shared-mime-info
      # https://github.com/lutris/lutris/issues/3965#issuecomment-1100904672
      (lutris.overrideAttrs (oldAttrs: {
        installPhase = (oldAttrs.installPhase or "") + ''
          mkdir -p $out/share
          rm $out/share/applications
          cp -R ${lutris-unwrapped}/share/applications $out/share
          sed -i -e 's/Exec=lutris/Exec=env WEBKIT_DISABLE_COMPOSITING_MODE=1 lutris/' $out/share/applications/*lutris*.desktop
        '';
      }))
      vulkan-tools
      gimp
      inkscape
      krita
      libreoffice
      onlyoffice-bin
      beancount
      fava
      arandr
      barrier
      ethtool
      pavucontrol
      ncdu
      qutebrowser
      luakit
      surf
      (qmk.overrideAttrs (oldAttrs: {
        propagatedBuildInputs = oldAttrs.propagatedBuildInputs
          ++ (with python3Packages; [ pyserial pillow ]);
      }))
      dfu-programmer
      vial
    ] ++ (let
      mkFirefox = { name, desktopName, profileName }:
        let
          pkg = (latest."${name}-bin".override {
            cfg.enableBrowserpass = true;
            cfg.enableTridactylNative = true;
          }).overrideAttrs (old: rec {
            desktopItem = makeDesktopItem {
              inherit name desktopName;
              exec = "${name} %U";
              icon = name;
              comment = "";
              genericName = "Web Browser";
              categories = [ "Network" "WebBrowser" ];
              mimeTypes = [
                "text/html"
                "text/xml"
                "application/xhtml+xml"
                "application/vnd.mozilla.xul+xml"
                "x-scheme-handler/http"
                "x-scheme-handler/https"
                "x-scheme-handler/ftp"
              ];
            };
          });
          wrapped = pkgs.writeShellScriptBin name ''
            exec ${pkg}/bin/firefox --no-remote -P ${profileName} "''${@}"
          '';
        in pkgs.symlinkJoin {
          inherit name;
          paths = [ wrapped pkg ];
        };
    in [
      (mkFirefox {
        name = "firefox-nightly";
        desktopName = "Firefox Nightly";
        profileName = "nightly";
      })
      (mkFirefox {
        name = "firefox-beta";
        desktopName = "Firefox Beta";
        profileName = "beta";
      })
      (mkFirefox {
        name = "firefox-esr";
        desktopName = "Firefox ESR";
        profileName = "esr";
      })
    ]) ++ [
      ungoogled-chromium
      google-chrome
      google-chrome-beta
      google-chrome-dev
      tor-browser-bundle-bin
      virt-manager
      qemu
      slack
      discord
      tdesktop
      skypeforlinux
      signal-desktop
      zoom-us
      element-desktop
      ferdium
      spotify
      # https://github.com/NixOS/nixpkgs/issues/179323
      prismlauncher
      manix
      cachix
      nix-prefetch-git
      nix-prefetch
      keybase
      comma
      zeal
      dasht

      # For dark mode toggling
      xfce.xfconf

      retroarchFull
      mangohud
      protonup

    ] ++ [

      #########
      # FONTS #
      #########

      # Emoji
      # emojione
      # twitter-color-emoji
      # twemoji-color-font
      # noto-fonts-emoji
      # noto-fonts-emoji-blob-bin
      joypixels

      # Classic fonts
      eb-garamond
      # helvetica-neue-lt-std
      libre-bodoni
      libre-caslon
      libre-franklin
      etBook

      # Microsoft fonts
      corefonts
      vistafonts

      # Metrically-compatible font replacements
      liberation_ttf
      liberation-sans-narrow
      meslo-lg

      # Libre fonts
      gentium-book-basic
      crimson
      dejavu_fonts
      overpass
      raleway
      comic-neue
      comic-relief
      fira
      fira-mono
      lato
      libertine
      libertinus
      montserrat
      f5_6
      route159
      aileron
      eunomia
      seshat
      penna
      ferrum
      medio
      tenderness
      vegur
      source-code-pro
      xkcd-font
      gyre-fonts

      # Font collections
      google-fonts
      league-of-moveable-type

      # Iosevka and friends
      # iosevka-bin we use the `nerdfonts` version
      (iosevka-bin.override { variant = "aile"; })
      (iosevka-bin.override { variant = "etoile"; })

      # Other Coding fonts
      # hack-font
      # go-font
      # hasklig
      # fira-code
      # inconsolata
      # mononoki
      # fantasque-sans-mono

      # Nerd Fonts but just the symbols
      # Set FontConfig to use it as a fallback for most monospaced fonts
      (nerdfonts.override { fonts = [ "Iosevka" "NerdFontsSymbolsOnly" ]; })
      (stdenv.mkDerivation rec {
        inherit (nerdfonts) version;
        pname = "nerdfonts-fontconfig";
        src = builtins.fetchurl
          "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/10-nerd-font-symbols.conf";
        dontUnpack = true;
        dontConfigure = true;
        dontBuild = true;
        installPhase = ''
          runHook preInstall

          fontconfigdir="$out/etc/fonts/conf.d"
          install -d "$fontconfigdir"
          install "$src" "$fontconfigdir/10-nerd-font-symbols.conf"

          runHook postInstall
        '';
        enableParallelBuilding = true;
      })
      emacs-all-the-icons-fonts

      # Apple Fonts
    ] ++ (let
      mkAppleFont = { name, src }:
        stdenv.mkDerivation {
          inherit name src;
          nativeBuildInputs = [ p7zip ];
          unpackCmd = "7z x $curSrc";
          postUnpack = ''
            cd $sourceRoot
            7z x *.pkg
            7z x Payload~
            cd ..
          '';
          dontConfigure = true;
          dontBuild = true;
          installPhase = ''
            runHook preInstall

            fontdir="$out/share/fonts/truetype"
            install -d "$fontdir"
            install "Library/Fonts"/* "$fontdir"

            runHook postInstall
          '';
          preferLocalBuild = true;
          allowSubstitutes = false;
          meta.license = lib.licenses.unfree;
        };
    in [
      (mkAppleFont {
        name = "san-francisco-pro";
        src = builtins.fetchurl
          "https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg";
      })
      (mkAppleFont {
        name = "san-francisco-compact";
        src = builtins.fetchurl
          "https://devimages-cdn.apple.com/design/resources/download/SF-Compact.dmg";
      })
      (mkAppleFont {
        name = "san-francisco-mono";
        src = builtins.fetchurl
          "https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg";
      })
      (mkAppleFont {
        name = "new-york";
        src = builtins.fetchurl
          "https://devimages-cdn.apple.com/design/resources/download/NY.dmg";
      })
    ]) ++ [

      # Non-latin character sets
      junicode

      # Fallback fonts
      cm_unicode
      xorg.fontcursormisc
      symbola
      freefont_ttf
      unifont
      noto-fonts
      noto-fonts-extra
      noto-fonts-cjk

    ];

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.05";
}
# vim: set foldmethod=indent foldcolumn=4 shiftwidth=2 tabstop=2 expandtab:
