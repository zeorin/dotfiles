# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)

{
  lib,
  config,
  osConfig,
  pkgs,
  self,
  nix-index-database,
  ...
}:

let
  myKey = "863F 093A CF82 D2C8 6FD7 FB74 5E1C 0971 FE4F 665A";

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
    isSshSession = pkgs.writeShellScript "is-ssh-session" ''
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
      addTmuxTerminfo = pkgs.writeShellScript "add-tmux-terminfo" ''
        cat <<EOF|${pkgs.ncurses}/bin/tic -x -
        tmux|tmux terminal multiplexer,
          ritm=\E[23m, rmso=\E[27m, sitm=\E[3m, smso=\E[7m, Ms@,
          use=xterm+tmux, use=screen,

        tmux-256color|tmux with 256 colors,
          use=xterm+256setaf, use=tmux,
        EOF
      '';
      sessionChooser = pkgs.writeShellScript "tmux-session-chooser" ''
        if [ "$TERM" != "dumb" ] && \
          [ -z "$TMUX" ] && \
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
      sessionChooserFish = pkgs.writeScript "tmux-session-chooser.fish" ''
        #!${pkgs.fish}/bin/fish

        if [ "$TERM" != "dumb" ] && \
          [ -z "$TMUX" ] && \
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
    };
    setWallpaper = pkgs.writeShellScript "set-wallpaper" ''
      color_scheme="$(${config.services.darkman.package}/bin/darkman get)"

      if [ "$color_scheme" = "dark" ]; then
        background_image_left="${./backgrounds/martian-terrain-dark-left.jpg}"
        background_image_right="${./backgrounds/martian-terrain-dark-right.jpg}"
      else
        background_image_left="${./backgrounds/martian-terrain-light-left.jpg}"
        background_image_right="${./backgrounds/martian-terrain-light-right.jpg}"
      fi

      # TODO: set wallpaper
    '';
  };
in
{
  # You can import other home-manager modules here
  imports = (builtins.attrValues self.outputs.homeModules) ++ [
    nix-index-database.homeModules.nix-index
    ./emacs
    ./oama
    ./email
  ];

  config = {
    home = {
      username = "zeorin";
      homeDirectory = "/home/${config.home.username}";
      keyboard = null;
      shell.enableShellIntegration = true;
      sessionVariables = with config.xdg; {
        LESS = "-FRXix2$";
        # Non-standard env var, found in https://github.com/i3/i3/blob/next/i3-sensible-terminal
        TERMINAL = "${pkgs.unstable.app2unit}/bin/app2unit-term";
        BATDIFF_USE_DELTA = "true";
        DELTA_FEATURES = "+side-by-side";

        EDITOR_URL = "editor://{path}:{line}";
        # Non-standard env var, found in https://github.com/yyx990803/launch-editor
        LAUNCH_EDITOR = pkgs.writeShellScript "launch-editor" ''
          file="$1"
          line="$2"
          column="$3"
          command="${pkgs.unstable.app2unit}/bin/app2unit-open \"editor://$file\""
          [ -n "$line" ] && command="$command:$line"
          [ -n "$column" ] && command="$command:$column"
          eval $command
        '';
        OPEN_IN_EDITOR = config.home.sessionVariables.VISUAL or config.home.sessionVariables.EDITOR;

        APP2UNIT_SLICES = "a=app-graphical.slice b=background-graphical.slice s=session-graphical.slice";

        # Hint electron apps to use wayland:
        NIXOS_OZONE_WL = "1";

        # Help some tools actually adhere to XDG Base Dirs
        CURL_HOME = "${configHome}/curl";
        INPUTRC = "${configHome}/readline/inputrc";
        NPM_CONFIG_USERCONFIG = "${configHome}/npm/npmrc";
        WGETRC = "${configHome}/wget/wgetrc";
        LESSHISTFILE = "${cacheHome}/less/history";
        PSQL_HISTORY = "${cacheHome}/pg/psql_history";
        XCOMPOSEFILE = "${configHome}/X11/xcompose";
        XCOMPOSECACHE = "${cacheHome}/X11/xcompose";
        GOPATH = "${dataHome}/go";
        MYSQL_HISTFILE = "${dataHome}/mysql_history";
        NODE_REPL_HISTORY = "${dataHome}/node_repl_history";
        STACK_ROOT = "${dataHome}/stack";
        WINEPREFIX = "${dataHome}/wineprefixes/default";

        LEDGER_FILE = "${userDirs.documents}/2. Areas/Finances/hledger.journal";

        # Suppress direnv's verbose output
        # https://github.com/direnv/direnv/issues/68#issuecomment-42525172
        DIRENV_LOG_FORMAT = "";

        DASHT_DOCSETS_DIR = "${dataFile.docsets.source}";
      };
      activation = with config.xdg; {
        createXdgCacheAndDataDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          # Cache dirs
          for dir in less pg X11; do
            run mkdir --parents $VERBOSE_ARG \
              ${cacheHome}/$dir
          done

          # Data dirs
          for dir in bash go pass stack wineprefixes; do
            run mkdir --parents $VERBOSE_ARG \
              ${dataHome}/$dir
          done
          run mkdir --parents $VERBOSE_ARG \
            --mode=700 ${dataHome}/gnupg

          # Flameshot dir
          run mkdir --parents $VERBOSE_ARG \
            ${config.home.homeDirectory}/Screenshots
        '';
      };
      shellAliases = {
        g = "git";
        e = "edit";
        m = "neomutt";
        o = "${pkgs.unstable.app2unit}/bin/app2unit-open";
        s = "systemctl";
        t = "tail -f";
        d = "docker";
        j = "journalctl -xe";
        ls = "${pkgs.lsd}/bin/lsd";
        l = "ls -l";
        la = "ls -a";
        lla = "ls -la";
        lt = "ls --tree";
        tree = "${pkgs.lsd}/bin/lsd --tree";
        cat = "bat";
        rg = "batgrep";
        ip = "ip -color=auto";
        grep = "grep --color=auto";
        diff = "batdiff";
        # Use `pass` to input SSH key passprases
        # TODO: fall back to regular passphrase entry if no GPG smartcard is
        # found / no key entry is found in the pass database
        ssh = toString (
          pkgs.writeShellScript "pass-ssh" ''
            set -euo pipefail

            export SSH_ASKPASS_REQUIRE=force
            export SSH_ASKPASS="${pkgs.writeShellScript "pass-askpass" ''
              set -euo pipefail

              die() {
                echo "$@" >&2
                exit 1
              }

              keyfile="$(echo "$1" | ${pkgs.gnused}/bin/sed -ne "s/^.*\(\/.*\)['\"]*:.*$/\1/")"
              [ -z "$keyfile" ] && die "Could not find key filename in prompt\n\"$1\""
              echo "Extracted key filename \"$keyfile\"" >&2

              comment="$(${pkgs.openssh}/bin/ssh-keygen -l -f "$keyfile" | ${pkgs.gawk}/bin/awk '{print $3}')"
              [ -z "$comment" ] && die "Could not find comment in key \"$keyfile\""
              echo "Comment from keyfile \"$keyfile\" is \"$comment\"" >&2

              sshdir="''${PASSWORDSTORE_SSH_DIR:-ssh}"
              passphrase="$(${pkgs.pass}/bin/pass show "$sshdir/$comment")"
              [ -z "$passphrase" ] && die "Could not find passphrase for \"$comment\""
              echo "Got passphrase for comment \"$comment\"" >&2

              echo "$passphrase"
            ''}"

            ${pkgs.openssh}/bin/ssh "$@"
          ''
        );
        # Use `pass` to input the sudo password
        sudo = toString (
          pkgs.writeShellScript "pass-sudo" ''
            set -euo pipefail

            export SUDO_ASKPASS="${pkgs.writeShellScript "pass-sudo-askpass" ''
              set -euo pipefail
              hostname="''${HOSTNAME:-"$(hostname)"}"
              hostsdir="''${PASSWORDSTORE_HOSTS_DIR:-hosts}"
              ${pkgs.pass}/bin/pass "$hostsdir/$hostname/$USER" | head -n1
            ''}"

            /usr/bin/env sudo --askpass "$@"
          ''
        );
      };
    };

    programs = {
      home-manager.enable = true;
      bash = {
        enable = true;
        initExtra = ''
          eval "$(batman --export-env)"
        '';
      };
      bat = {
        enable = true;
        extraPackages = with pkgs.bat-extras; [
          batgrep
          batman
          batpipe
          batdiff
        ];
        config = {
          theme = "Nord";
          italic-text = "always";
          map-syntax = [ ".ignore:Git Ignore" ];
        };
      };
      browserpass = {
        enable = true;
        browsers = [
          "chrome"
          "chromium"
        ];
      };
      delta = {
        enable = true;
        enableGitIntegration = true;
        options = {
          hyperlinks = true;
          hyperlinks-file-link-format = "editor://{path}:{line}:{column}";
          features = lib.concatStringsSep " " [
            "line-numbers"
            "navigate"
            "zebra-dark"
            "collared-trogon"
          ];
        };
      };
      dircolors = {
        enable = true;
        extraConfig = builtins.readFile "${pkgs.nord-dircolors}/src/dir_colors";
      };
      direnv = {
        enable = true;
        nix-direnv.enable = true;
        config = {
          global = {
            strict_env = true;
            warn_timeout = "30s";
          };
        };
      };
      firefox = {
        enable = true;
        package = pkgs.firefox.override {
          nativeMessagingHosts = with pkgs; [
            browserpass
            kdePackages.plasma-browser-integration
            tridactyl-native
          ];
        };
        profiles =
          let
            extensions =
              with pkgs.nur.repos.rycee.firefox-addons;
              [
                browserpass
                darkreader
                ghosttext
                org-capture
                plasma-integration
                react-devtools
                reduxdevtools
                sponsorblock
                tab-session-manager
                tridactyl
                ublock-origin
                wallabagger
                wayback-machine
              ]
              ++ (with pkgs.nur.repos.meain.firefox-addons; [ containerise ]);
            commonSettings = {
              "browser.startup.page" = 3; # resume previous session
              "browser.startup.homepage" = "about:blank";
              "browser.newtabpage.enabled" = false;
              "browser.newtab.preload" = false;
              "browser.newtab.url" = "about:blank";
              "browser.startup.homepage_override.mstone" = "ignore"; # hide welcome & what's new notices
              "browser.messaging-system.whatsNewPanel.enabled" = false; # hide what's new
              "browser.menu.showViewImageInfo" = true; # restore "view image info"
              "browser.ctrlTab.recentlyUsedOrder" = false; # use chronological order
              "browser.display.show_image_placeholders" = false;
              "browser.tabs.loadBookmarksInTabs" = true; # open bookmarks in a new tab
              "browser.urlbar.decodeURLsOnCopy" = true;
              "editor.truncate_user_pastes" = false; # don't truncate pasted passwords
              "media.videocontrols.picture-in-picture.video-toggle.has-used" = true; # smaller picture-in-picture icon
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
              "browser.urlbar.suggest.topsites" = false; # disable dropdown suggestions with empty query
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
              # On i3 tabs in titlebar are pretty ugly
              "browser.tabs.inTitlebar" = 0;
              # Allow all fontconfig substitutions
              "gfx.font_rendering.fontconfig.max_generic_substitutions" = 127;
              # Use system emoji
              "font.name-list.emoji" = "emoji";
              "gfx.font_rendering.opentype_svg.enabled" = false;
              # HTTPS-only
              "dom.security.https_only_mode" = true;
              "dom.security.https_only_mode_ever_enabled" = true;
              # XDG Desktop Portal Integration
              "widget.use-xdg-desktop-portal.file-picker" = 1;
              "widget.use-xdg-desktop-portal.mime-handler" = 1;
              "widget.use-xdg-desktop-portal.settings" = 1;
              "widget.use-xdg-desktop-portal.location" = 1;
              "widget.use-xdg-desktop-portal.open-uri" = 1;
              # Gluten-free
              "cookiebanners.bannerClicking.enabled" = true;
              "cookiebanners.service.mode" = 2;
              "cookiebanners.service.mode.privateBrowsing" = 2;
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
              # "dom.ipc.processCount" = -1; # as many as FF wants
              # "network.http.max-persistent-connections-per-server" = 6; # default
              # "network.http.max-persistent-connections-per-server" = 10;
            };
            enableUserChrome = {
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            };
            saneNewTab = {
              # Don't open links in new tabs, except when it makes sense
              "browser.link.open_newwindow" = 1; # force new window into same tab
              "browser.link.open_newwindow.restriction" = 2; # except for script windows with features
              "browser.link.open_newwindow.override.external" = 3; # open external links in a new tab in last active window
              "browser.newtab.url" = "about:blank";
            };
          in
          {
            personal = {
              id = 0;
              isDefault = true;
              settings =
                commonSettings // noNoiseSuppression // performanceSettings // enableUserChrome // saneNewTab;
              userChrome = ''
                @import url('${pkgs.firefox-csshacks}/chrome/window_control_placeholder_support.css');
                @import url('${pkgs.firefox-csshacks}/chrome/hide_tabs_toolbar.css');
                @import url('${pkgs.firefox-csshacks}/chrome/autohide_toolbox.css');
              '';
              extensions.packages = extensions;
            };
            developer-edition = {
              id = 1;
              settings = commonSettings // noNoiseSuppression;
              extensions.packages = extensions;
            };
            beta = {
              id = 2;
              settings = commonSettings // noNoiseSuppression;
              extensions.packages = extensions;
            };
            esr = {
              id = 3;
              settings = commonSettings // noNoiseSuppression;
              extensions.packages = extensions;
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

            # CTRL+Backspace deletes work
            bind --user \b backward-kill-path-component
            bind --user -M insert \b backward-kill-path-component

            # Inhibit empty command line submissions
            # https://github.com/fish-shell/fish-shell/issues/7797
            bind --user \r 'commandline | string trim | string length -q \
              && transient_execute \
              || commandline -r ""'
            bind --user -M insert \r 'commandline | string trim | string length -q \
              && transient_execute \
              || commandline -r ""'
          '';
          mkcd = {
            description = "Create a directory and change into it";
            body = "mkdir -p $argv[1] && cd $argv[1]";
          };
          fish_nord_theme = {
            description = "Set fish's colours";
            argumentNames = [ "variant" ];
            body = ''
              # Inspired by https://github.com/ericvw/dotfiles/blob/main/fish/.config/fish/conf.d/nordtheme.fish

              argparse --max-args=1 -- $argv
              or return

              set -q variant; or set -l variant dark

              set -l nord0 2e3440
              set -l nord1 3b4252
              set -l nord2 434c5e
              set -l nord3 4c566a
              set -l nord4 d8dee9
              set -l nord5 e5e9f0
              set -l nord6 eceff4
              set -l nord7 8fbcbb
              set -l nord8 88c0d0
              set -l nord9 81a1c1
              set -l nord10 5e81ac
              set -l nord11 bf616a
              set -l nord12 d08770
              set -l nord13 ebcb8b
              set -l nord14 a3be8c
              set -l nord15 b48ead

              if test $variant = dark
                set -U fish_color_normal normal
                set -U fish_color_command $nord8
                set -U fish_color_keyword $nord9
                set -U fish_color_quote $nord14
                set -U fish_color_redirection $nord15 --bold
                set -U fish_color_end $nord9
                set -U fish_color_error $nord11
                set -U fish_color_param $nord4
                set -U fish_color_valid_path --underline
                set -U fish_color_option $nord7
                set -U fish_color_comment $nord3 --italics
                set -U fish_color_selection $nord4 --bold --background=$nord2
                set -U fish_color_operator $nord9
                set -U fish_color_escape $nord13
                set -U fish_color_autosuggestion $nord3
                set -U fish_color_cwd $nord10
                set -U fish_color_cwd_root $nord11
                set -U fish_color_user $nord14
                set -U fish_color_host $nord14
                set -U fish_color_host_remote $nord13
                set -U fish_color_status $nord11
                set -U fish_color_cancel --reverse
                set -U fish_color_search_match --bold --background=$nord2
                set -U fish_color_history_current $nord5 --bold
                set -U fish_pager_color_progress $nord1 --background=$nord12
                set -U fish_pager_color_completion $nord5
                set -U fish_pager_color_prefix normal --bold --underline
                set -U fish_pager_color_description $nord13 --italics
                set -U fish_pager_color_selected_background --background=$nord2
              else if test $variant = light
                set -U fish_color_normal normal
                set -U fish_color_command $nord2
                set -U fish_color_keyword $nord7
                set -U fish_color_quote $nord14
                set -U fish_color_redirection $nord15 --bold
                set -U fish_color_end $nord7
                set -U fish_color_error $nord11
                set -U fish_color_param $nord10
                set -U fish_color_valid_path --underline
                set -U fish_color_option $nord9
                set -U fish_color_comment $nord4 --italics
                set -U fish_color_selection $nord2 --bold --background=$nord4
                set -U fish_color_operator $nord7
                set -U fish_color_escape $nord13
                set -U fish_color_autosuggestion $nord4
                set -U fish_color_cwd $nord8
                set -U fish_color_cwd_root $nord11
                set -U fish_color_user $nord14
                set -U fish_color_host $nord14
                set -U fish_color_host_remote $nord13
                set -U fish_color_status $nord11
                set -U fish_color_cancel --reverse
                set -U fish_color_search_match --bold --background=$nord4
                set -U fish_color_history_current $nord1 --bold
                set -U fish_pager_color_progress $nord5 --background=$nord12
                set -U fish_pager_color_completion $nord1
                set -U fish_pager_color_prefix normal --bold --underline
                set -U fish_pager_color_description $nord13 --italics
                set -U fish_pager_color_selected_background --background=$nord4
              else
                echo "Unknown variant: $variant"
              end
            '';
          };
          # https://dandavison.github.io/delta/tips-and-tricks/toggling-delta-features.html
          delta-toggle = {
            description = "Toggle delta features such as side-by-side";
            body = ''
              set --export --global DELTA_FEATURES "$(${
                pkgs.stdenvNoCC.mkDerivation {
                  pname = "-delta-features-toggle";
                  version = "unstable-2024-12-28";
                  preferLocalBuild = true;
                  allowSubstitutes = false;
                  src = pkgs.fetchurl {
                    url = "https://raw.githubusercontent.com/dandavison/tools/b9522d5ed542bf08c0cb62adddcfaf61a6876873/python/-delta-features-toggle";
                    hash = "sha256-c0/Cqp4giyp+oZ3LD+44qDmqzBNM16ezoAqVV7UKxLo=";
                  };
                  dontUnpack = true;
                  dontConfigure = true;
                  dontBuild = true;
                  installPhase = ''
                    runHook preInstall

                    substitute $src $out \
                      --replace "/usr/bin/python3" "${pkgs.python3}/bin/python"
                    chmod +x $out

                    runHook postInstall
                  '';
                }
              } $argv[1] | tee /dev/stderr)"
            '';
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

          fish_nord_theme dark

          # Put a newline under the last command
          # https://github.com/starship/starship/issues/560#issuecomment-1465630645
          function echo_prompt --on-event fish_postexec
            echo ""
          end

          # Don't try to interpret Escape key sequences
          set -g fish_escape_delay_ms 10
          set -g fish_sequence_key_delay 0

          batman --export-env | source
          eval (batpipe)
        '';
        plugins = [
          {
            name = "done";
            src = pkgs.fetchFromGitHub {
              owner = "franciscolourenco";
              repo = "done";
              rev = "1.19.2";
              hash = "sha256-VSCYsGjNPSFIZSdLrkc7TU7qyPVm8UupOoav5UqXPMk=";
            };
          }
        ];
      };
      fzf = {
        enable = true;
        defaultCommand = "${pkgs.fd}/bin/fd --type file --strip-cwd-prefix --glob";
        fileWidgetCommand = "${pkgs.fd}/bin/fd --type empty --type file --strip-cwd-prefix --hidden --follow --glob";
        changeDirWidgetCommand = "${pkgs.fd}/bin/fd --type empty --type directory --strip-cwd-prefix --hidden --follow --glob";
      };
      git = {
        enable = true;
        includes = [
          {
            path = "${pkgs.delta.src}/themes.gitconfig";
          }
        ];
        maintenance = {
          enable = true;
          repositories = [
            "${config.home.homeDirectory}/Code/nixpkgs"
          ];
        };
        settings = {
          user.useConfigOnly = true;
          user.name = "Xandor Schiefer";
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
          push.default = "current";
          fetch.prune = true;
          pull.rebase = true;
          rebase = {
            autoStash = true;
            updateRefs = true;
          };
          advice = {
            statusHints = false;
            pushNonFastForward = false;
          };
          diff = {
            algorithm = "histogram";
            renames = "copies";
            mnemonicprefix = true;
            tool = "nvimdiff";
            colorMoved = "default";
          };
          difftool.prompt = false;
          "difftool \"nvimdiff\"".cmd = ''$VISUAL -d "$LOCAL" "$REMOTE"'';
          merge = {
            stat = true;
            tool = "nvimdiff";
            autoStash = true;
            conflictStyle = "zdiff3";
          };
          mergetool.prompt = false;
          "mergetool \"nvimdiff\"".cmd =
            ''$VISUAL -d -c '4wincmd w | wincmd J'  "$LOCAL" "$BASE" "$REMOTE" "$MERGED"'';
          branch.autosetupmerge = true;
          rerere = {
            enabled = true;
            autoUpdate = true;
          };
          log.abbrevCommit = true;
          blame.ignoreRevsFile = ".git-blame-ignore-revs";
          "delta \"magit-delta\"" = {
            line-numbers = false;
          };
          alias = {
            a = "add";
            b = "branch";
            # Use commitizen if it’s installed, otherwise just use `git commit`
            c = lib.strings.removeSuffix "\n" ''
              !f() {
                if command -v git-cz >/dev/null 2>&1; then
                  git-cz "$@"
                else
                  git commit "$@"
                fi
              }
              f
            '';
            co = "checkout";
            d = "diff";
            p = "push";
            r = "rebase";
            s = "status";
            u = "unstage";
            unstage = "reset HEAD --";
            last = "log -1 HEAD";
            stash-unapply = lib.strings.removeSuffix "\n" ''
              !git stash show -p |
                git apply -R
            '';
            assume = "update-index --assume-unchanged";
            unassume = "update-index --no-assume-unchanged";
            assumed = lib.strings.removeSuffix "\n" ''
              !git ls-files -v |
                ${pkgs.gnugrep}/bin/grep '^h' |
                cut -c 3-
            '';
            assume-all = lib.strings.removeSuffix "\n" ''
              !git status --porcelain |
                ${pkgs.gawk}/bin/awk {'print $2'} |
                ${pkgs.findutils}/bin/xargs -r git assume
            '';
            unassume-all = lib.strings.removeSuffix "\n" ''
              !git assumed |
                ${pkgs.findutils}/bin/xargs -r git unassume
            '';
            skip = "update-index --skip-worktree";
            unskip = "update-index --no-skip-worktree";
            skipped = lib.strings.removeSuffix "\n" ''
              !git ls-files -t |
                ${pkgs.gnugrep}/bin/grep '^S' |
                cut -c 3-
            '';
            skip-all = lib.strings.removeSuffix "\n" ''
              !git status --porcelain |
                ${pkgs.gawk}/bin/awk {'print $2'} |
                ${pkgs.findutils}/bin/xargs -r git skip
            '';
            unskip-all = lib.strings.removeSuffix "\n" ''
              !git skipped |
                ${pkgs.findutils}/bin/xargs -r git unskip
            '';
            edit-dirty = lib.strings.removeSuffix "\n" ''
              !git status --porcelain |
                ${pkgs.gnused}/bin/sed s/^...// |
                ${pkgs.findutils}/bin/xargs -r "$EDITOR"
            '';
            tracked-ignores = lib.strings.removeSuffix "\n" ''
              !git ls-files |
                git check-ignore --no-index --stdin
            '';
            # https://www.erikschierboom.com/2020/02/17/cleaning-up-local-git-branches-deleted-on-a-remote/
            branch-purge = lib.strings.removeSuffix "\n" ''
              !git for-each-ref \
                --format='%(if:equals=[gone])%(upstream:track)%(then)%(refname:short)%(end)' \
                refs/heads |
                ${pkgs.findutils}/bin/xargs -r git branch -d
            '';
          }
          // (
            let
              git-ignore = "!${pkgs.writeShellScript "git-ignore" ''
                # Unofficial Bash strict mode
                set -euo pipefail

                # Execute from the correct directory
                cd "$GIT_PREFIX"

                # What were we invoked as?
                subcommand=ignore # ignore | exclude

                # Utility functions
                usage() {
                    cat <<EOF
                    Usage: git $subcommand [-h|--help] [-n|--dry-run]
                        [-r|--relative] [-a|--absolute]
                        [-c|--current] [-t|--toplevel] [-e|--exclude] [-g|--global]
                        [--] <pattern>...

                    Add the patterns to a gitignore(5) file, and remove any currently tracked
                    files that match from the index. Does not delete the actual files from the
                    disk, and does not commit the changes; their removal from the index is
                    staged.

                    -h, --help
                        Display this help text and exit.

                    -n, --dry-run
                        Don't take any actions, instead print representation of actions to
                        stdout.

                    -r, --relative
                        Patterns are interpreted relative to the current directory.
                        This is the default behaviour.

                    -a, --absolute
                        Patterns are interpreted relative to the root of the worktree. Implies
                        --toplevel if --exclude or --global are not supplied.

                    -c, --current
                        Add the patterns to a gitignore file in the current directory.$([ "$subcommand" = ignore ] && printf "\n        This is the default behaviour.")

                    -t, --toplevel
                        Add the patterns to a gitignore file at the top level of the worktree.

                    -e, --exclude
                        Add the patterns to \$GIT_DIR/info/exclude.$([ "$subcommand" = exclude ] && printf "\n        This is the default behaviour.")

                    -g, --global
                        Add the patterns to core.excludesFile (~/.config/git/ignore if not
                        explicitly set).

                EOF
                }
                die() {
                  echo "$@" >&2
                  exit 1
                }

                # Parse arguments
                args=$(
                  getopt --options neagtcrh? \
                      --longoptions subcommand:,dry-run,exclude,absolute,global,toplevel,top-level,current,relative,help \
                      --name "$(basename "$0")" \
                      -- "$@"
                )
                if [ $? != 0 ]; then die "Terminating..."; fi
                eval set -- "$args"

                # Gather info
                global_excludes_filename="$(git config --global --get --default="''${XDG_CONFIG_HOME:="$HOME/.config"}/git/ignore" core.excludesFile)"
                git_dir="$(git rev-parse --path-format=absolute --git-dir | sed -e "s#/\$##g")"
                toplevel="$(git rev-parse --path-format=absolute --show-toplevel | sed -e "s#/\$##g")"
                prefix="$(git rev-parse --show-prefix | sed -e "s#/\$##g")"
                cwd="$(pwd)"

                # Defaults
                exclude_file=current # current | toplevel | exclude | global
                absolute=false # false | true
                dry_run=false # false | true

                # Set options
                while true; do
                  case "$1" in
                    --subcommand)
                      subcommand="$2"
                      shift 2
                      ;;
                    -n | --dry-run)
                      dry_run=true
                      shift
                      ;;
                    -e | --exclude)
                      exclude_file=exclude
                      shift
                      ;;
                    -a | --absolute)
                      absolute=true
                      shift
                      ;;
                    -g | --global)
                      exclude_file=global
                      shift
                      ;;
                    -t | --toplevel | --top-level)
                      exclude_file=toplevel
                      shift
                      ;;
                    -c | --current)
                      exclude_file=current
                      shift
                      ;;
                    -r | --relative)
                      absolute=false
                      shift
                      ;;
                    -h | --help)
                      usage
                      exit 0
                      ;;
                    --)
                      shift
                      break
                      ;;
                    *)
                      die "Internal error!"
                      ;;
                  esac
                done

                # Exit if called without patterns
                [ $# = 0 ] && (usage; exit 1)

                # Set exclude_file if called as exclude
                [ "$subcommand" = exclude ] && exclude_file=exclude

                # Set exclude_pattern_scope
                # exclude_pattern_scope is prepended to each pattern the user gives us
                case "$absolute" in
                  true)
                    # --toplevel is implied if --exclude or --global are not provided when
                    # --absolute is
                    [ "$exclude_file" != exclude ] && [ "$exclude_file" != global ] && exclude_file=toplevel
                    exclude_pattern_scope=""
                    prefix=""
                    ;;
                  false)
                    exclude_pattern_scope="$(
                      if [ "$exclude_file" = "current" ]; then
                        echo ""
                      else
                        echo "$prefix"
                      fi
                    )"
                    ;;
                  *)
                    die "Unknown \$absolute value $absolute!"
                    ;;
                esac

                # Set excludes_filepath
                case "$exclude_file" in
                  current)
                    excludes_filepath="$cwd/.gitignore"
                    ;;
                  toplevel)
                    excludes_filepath="$toplevel/.gitignore"
                    ;;
                  exclude)
                    excludes_filepath="$git_dir/info/exclude"
                    ;;
                  global)
                    excludes_filepath="$global_excludes_filename"
                    ;;
                  *)
                    die "Unknown \$exclude_file value $exclude_file!"
                    ;;
                esac

                declare -a scoped_exclude_patterns
                declare -a exclude_patterns

                for pattern in "$@"; do
                  # Prepend the scope to the user's patterns
                  scoped_exclude_patterns+=("$(
                    if [ -z "$exclude_pattern_scope" ]; then
                      echo "$pattern"
                    elif [[ "$pattern" == /* ]]; then
                      echo "$exclude_pattern_scope$pattern"
                    else
                      echo "$exclude_pattern_scope/**/$pattern"
                    fi
                  )")

                  # When matching currently tracked files against the user's provided patterns,
                  # the patterns we provide to git-ls-files must be relative to the root of the
                  # work tree, thus they might be different from what we actually put in the
                  # excludes file
                  exclude_patterns+=("$(
                    if [ -z "$prefix" ]; then
                      echo "$pattern"
                    elif [[ "$pattern" == /* ]]; then
                      echo "$prefix$pattern"
                    else
                      echo "$prefix/**/$pattern"
                    fi
                  )")
                done

                if $dry_run; then
                  # Print pretty paths
                  echo "cat <<EOF >>$([ "$exclude_file" != global ] && realpath --relative-to "$cwd" "$excludes_filepath" || echo "''${excludes_filepath/#"$HOME"/\~}")"
                  printf "%s\n" "''${scoped_exclude_patterns[@]}"
                  echo "EOF"
                  tmp="$(mktemp)"
                  printf "%s\n" "''${exclude_patterns[@]}" >>"$tmp"
                  git ls-files --cached --ignored --exclude-from="$tmp" -- "$toplevel" |
                    xargs printf "git rm --cached '%s'\n"
                  rm "$tmp"
                else
                  printf "%s\n" "''${scoped_exclude_patterns[@]}" >>"$excludes_filepath"
                  tmp="$(mktemp)"
                  printf "%s\n" "''${exclude_patterns[@]}" >>"$tmp"
                  git ls-files --cached --ignored --exclude-from="$tmp" -- "$toplevel" |
                    xargs git rm --cached -- &>/dev/null
                  rm "$tmp"
                fi
              ''}";
            in
            {
              ignore = "${git-ignore} --subcommand ignore";
              exclude = "${git-ignore} --subcommand exclude";
            }
          )
          // {
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
            lg1-specific = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'";
            lg2-specific = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'";
            lg3-specific = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset) %C(bold cyan)(committed: %cD)%C(reset) %C(auto)%d%C(reset)%n''          %C(white)%s%C(reset)%n''          %C(dim white)- %an <%ae> %C(reset) %C(dim white)(committer: %cn <%ce>)%C(reset)'";
            # https://docs.gitignore.io/use/command-line
            ignore-boilerplate = lib.strings.removeSuffix "\n" ''
              !f() {
                ${pkgs.curl}/bin/curl -sL "https://www.gitignore.io/api/$@" 2>/dev/null;
              }
              f
            '';
          };
        };
        signing = {
          key = myKey;
          signByDefault = true;
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
          default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
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
        package =
          let
            kitty = pkgs.kitty;
          in
          lib.attrsets.recursiveUpdate kitty {
            passthru.set-theme = pkgs.writeShellScript "kitty-set-theme" ''
              ${config.programs.kitty.package}/bin/kitty +kitten themes --reload-in=all --config-file-name="theme.conf" "$@"
            '';
          };
        font = {
          name = "Iosevka NF Light";
          size = 9;
        };
        keybindings = {
          "kitty_mod+v" = "paste_from_clipboard";
          "kitty_mod+plus" = "change_font_size all +1.0";
          "kitty_mod+minus" = "change_font_size all -1.0";
          "kitty_mod+backspace" = "change_font_size all 0";
          "kitty_mod+u" = "input_unicode_character";
        };
        themeFile = "Nord";
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
        };
        extraConfig = ''
          include theme.conf

          clipboard_control write-primary write-clipboard no-append

          # symbol_map ${
            with builtins;
            with lib;
            with strings;
            trivial.pipe (fileContents (toString (pkgs.emoji-variation-sequences))) [
              (splitString "\n")
              (filter (line: (stringLength line) > 0 && (substring 0 1 line) != "#"))
              (map (line: elemAt (splitString " " line) 0))
              lists.unique
              (filter (
                codepoint:
                !(elem codepoint [
                  "0023" # #
                  "002A" # *
                  "0030" # 0
                  "0031" # 1
                  "0032" # 2
                  "0033" # 3
                  "0034" # 4
                  "0035" # 5
                  "0036" # 6
                  "0037" # 7
                  "0038" # 8
                  "0039" # 9
                  # "00A9" # ©
                  # "00AE" # ®
                  # "2122" # ™
                ])
              ))
              (concatMapStringsSep "," (codepoint: "U+${codepoint}"))
            ]
          } Twitter Color Emoji
        '';
      };
      less = {
        enable = true;
        config = ''
          #line-edit
          ^P  up
          ^N  down
        '';
      };
      mpv = {
        enable = true;
        config = {
          save-position-on-quit = "";
          hwdec = "auto-safe";
          vo = "gpu";
          profile = "gpu-hq";
          ytdl-format = "bestvideo[height<=?720][fps<=?30][vcodec!=?vp9]+bestaudio/best";
          osd-bar = false;
        };
        bindings = {
          "space" = "cycle pause; script-binding uosc/flash-pause-indicator";
          "right" = "seek 5";
          "left" = "seek -5";
          "shift+right" = "seek 30; script-binding uosc/flash-timeline";
          "shift+left" = "seek -30; script-binding uosc/flash-timeline";
          "m" = "no-osd cycle mute; script-binding uosc/flash-volume";
          "up" = "no-osd add volume  10; script-binding uosc/flash-volume";
          "down" = "no-osd add volume -10; script-binding uosc/flash-volume";
          "[" = "no-osd add speed -0.25; script-binding uosc/flash-speed";
          "]" = "no-osd add speed  0.25; script-binding uosc/flash-speed";
          "\\" = "no-osd set speed 1; script-binding uosc/flash-speed";
          ">" = "script-binding uosc/next; script-message-to uosc flash-elements top_bar,timeline";
          "<" = "script-binding uosc/prev; script-message-to uosc flash-elements top_bar,timeline";
          "tab" = "script-binding uosc/toggle-ui";
          "menu" = "script-binding uosc/menu";
          "mbtn_right" = "script-binding uosc/menu";
          "s" = "script-binding uosc/subtitles #! Subtitles";
          "a" = "script-binding uosc/audio #! Audio tracks";
          "q" = "script-binding uosc/stream-quality #! Stream quality";
          "p" = "script-binding uosc/items #! Playlist";
          "c" = "script-binding uosc/chapters #! Chapters";
          "alt+>" = "script-binding uosc/delete-file-next #! Navigation > Delete file & Next";
          "alt+<" = "script-binding uosc/delete-file-prev #! Navigation > Delete file & Prev";
          "alt+esc" = "script-binding uosc/delete-file-quit #! Navigation > Delete file & Quit";
          "o" = "script-binding uosc/open-file #! Navigation > Open file";
          # "#" = "set video-aspect-override \"-1\" #! Utils > Aspect ratio > Default";
          # "#" = "set video-aspect-override \"16:9\" #! Utils > Aspect ratio > 16:9";
          # "#" = "set video-aspect-override \"4:3\" #! Utils > Aspect ratio > 4:3";
          # "#" = "set video-aspect-override \"2.35:1\" #! Utils > Aspect ratio > 2.35:1";
          # "#" = "script-binding uosc/audio-device #! Utils > Audio devices";
          # "#" = "script-binding uosc/editions #! Utils > Editions";
          "ctrl+s" = "async screenshot #! Utils > Screenshot";
          "alt+i" = "script-binding uosc/keybinds #! Utils > Key bindings";
          "O" = "script-binding uosc/show-in-directory #! Utils > Show in directory";
          # "#" = "script-binding uosc/open-config-directory #! Utils > Open config directory";
          # "#" = "script-binding uosc/update #! Utils > Update uosc";
          "R" = ''script-message-to uosc show-submenu #! Utils > Aspect ratio'';
          "F" = "script-binding quality_menu/video_formats_toggle";
          "Alt+f" = "script-binding quality_menu/audio_formats_toggle";
        };
        scripts = with pkgs.mpvScripts; [
          uosc
          thumbfast
          sponsorblock
          mpv-playlistmanager
          quality-menu
          mpris
          # autodeint
          # autocrop
          # acompressor
        ];
        scriptOpts = {
          thumbfast = {
            network = true;
            hwdec = true;
          };
          playlistmanager = {
            resolve_url_titles = true;
          };
          uosc = {
            click_threshold = 300;
            click_command = "cycle pause; script-binding uosc/flash-pause-indicator";
          };
        };
      };
      nix-index.enable = true;
      nix-index-database.comma.enable = true;
      obs-studio = {
        enable = true;
        package = pkgs.unstable.obs-studio;
        plugins = with pkgs.unstable.obs-studio-plugins; [
          wlrobs
        ];
      };
      password-store = {
        enable = true;
        package = pkgs.pass.withExtensions (
          exts: with exts; [
            (pass-otp.overrideAttrs (
              oldAttrs:
              let
                perl-pass-otp =
                  with pkgs.perlPackages;
                  buildPerlPackage {
                    pname = "Pass-OTP";
                    version = "1.5";
                    src = pkgs.fetchurl {
                      url = "mirror://cpan/authors/id/J/JB/JBAIER/Pass-OTP-1.5.tar.gz";
                      hash = "sha256-GujxwmvfSXMAsX7LRiI7Q9YgsolIToeFRYEVAYFJeaM=";
                    };
                    buildInputs = [
                      ConvertBase32
                      DigestHMAC
                      DigestSHA3
                      MathBigInt
                    ];
                    doCheck = false;
                  };
              in
              {
                version = "1.2.0.r29.a364d2a";
                src = pkgs.fetchFromGitHub {
                  owner = "tadfisher";
                  repo = "pass-otp";
                  rev = "a364d2a71ad24158a009c266102ce0d91149de67";
                  hash = "sha256-q9m6vkn+IQyR/ZhtzvZii4uMZm1XVeBjJqlScaPsL34=";
                };
                buildInputs = [ perl-pass-otp ];
                patchPhase = ''
                  sed -i -e 's|OATH=\$(which oathtool)|OATH=${perl-pass-otp}/bin/oathtool|' otp.bash
                  sed -i -e 's|OTPTOOL=\$(which otptool)|OTPTOOL=${perl-pass-otp}/bin/otptool|' otp.bash
                '';
              }
            ))
            pass-import
            pass-audit
            pass-update
            pass-checkup
            pass-genphrase
            pass-tomb
          ]
        );
        settings = {
          PASSWORD_STORE_DIR = "${config.xdg.dataHome}/password-store";
          PASSWORD_STORE_GPG_OPTS = "--no-throw-keyids";
          PASSWORD_STORE_GENERATED_LENGTH = "128";
          PASSWORD_STORE_CHARACTER_SET = "[:print:]"; # All printable characters
        };
      };
      rofi = {
        enable = true;
        pass = {
          enable = true;
          package = pkgs.rofi-pass-wayland;
          extraConfig =
            let
              remove-binding =
                binding: str:
                let
                  bindings = lib.strings.splitString "," str;
                in
                let
                  newBindings = lib.lists.remove binding bindings;
                in
                lib.strings.concatStringsSep "," newBindings;
            in
            with config.programs.rofi.extraConfig;
            ''
              # rofi command. Make sure to have "$@" as last argument
              _rofi () {
                  ${config.programs.rofi.package}/bin/rofi \
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

              _clip_in_primary() {
                ${pkgs.wl-clipboard}/bin/wl-copy --primary
              }

              _clip_in_clipboard() {
                ${pkgs.wl-clipboard}/bin/wl-copy
              }

              _clip_out_primary() {
                ${pkgs.wl-clipboard}/bin/wl-paste --primary
              }

              _clip_out_clipboard() {
                ${pkgs.wl-clipboard}/bin/wl-paste
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
              # copy_menu="Control+c"
              action_menu="Control+a"
              type_menu="Control+t"
              help="Control+h"
              switch="Control+x"
              insert_pass="Control+n"
            '';
        };
        font = "Iosevka Nerd Font 12";
        terminal = "${pkgs.unstable.app2unit}/bin/app2unit-term";
        extraConfig = {
          show-icons = true;
          # Remove some keys from the default bindings
          kb-accept-entry = "Control+m,Return,KP_Enter"; # Removed Control+j
          kb-remove-to-eol = ""; # Removed Control+k
          # Set our custom bindings
          kb-row-down = "Down,Control+n,Control+j";
          kb-row-up = "Up,Control+p,Control+k";
          # Unit-awareness
          run-command = "${pkgs.unstable.app2unit}/bin/app2unit -- {cmd}";
          run-shell-command = ''{terminal} -e "${pkgs.fish}/bin/fish" -ic "{cmd} && read"'';
        };
        theme =
          let
            # Use `mkLiteral` for string-like values that should show without
            # quotes, e.g.:
            # {
            #   foo = "abc"; => foo: "abc";
            #   bar = mkLiteral "abc"; => bar: abc;
            # };
            inherit (config.lib.formats.rasi) mkLiteral;
          in
          {
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
            entry = {
              vertical-align = mkLiteral "0.5";
            };
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
            "element normal normal" = {
              text-color = mkLiteral "@fg0";
            };
            "element normal urgent" = {
              text-color = mkLiteral "@urgent-color";
            };
            "element normal active" = {
              text-color = mkLiteral "@accent-color";
            };
            "element selected" = {
              text-color = mkLiteral "@bg0";
            };
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
        enableDefaultConfig = false;
        matchBlocks."*" = {
          # Enable compression for slow networks, for fast ones this slows it down
          # compression = true;
          # By default add the key to the agent so we're not asked for the passphrase again
          addKeysToAgent = "yes";
          # Share connections to same host
          controlMaster = "auto";
          controlPath = "\${XDG_RUNTIME_DIR}/master-%r@%n:%p";
          controlPersist = "5m";
          extraOptions = {
            # Only attempt explicitly specified identities
            IdentitiesOnly = "yes";
            IdentityFile = "~/.ssh/id_ed25519";

            # Use a faster cipher
            Ciphers = "aes128-gcm@openssh.com,aes256-gcm@openssh.com,chacha20-poly1305@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr";

            # Login more quickly by bypassing IPv6 lookup
            AddressFamily = "inet";

            # Update GPG's startup tty for every ssh command
            # exec = ''"${config.programs.gpg.package}/bin/gpg-connect-agent updatestartuptty /bye"'';
          };
        };
        includes = [ "config_local" ];
      };
      starship = {
        enable = true;
        enableTransience = true;
        settings = {
          add_newline = false;
          format = "$character";
          right_format = "$all";
        };
      };
      tmux = {
        enable = true;

        sensibleOnTop = true;
        mouse = true;
        focusEvents = true;
        aggressiveResize = true;
        clock24 = true;
        escapeTime = 0;
        historyLimit = 50000;

        keyMode = "vi";
        shortcut = "Space";
        terminal = "tmux-256color";

        extraConfig = ''
          # Vim-style selection
          unbind-key -T copy-mode-vi Space
          bind-key -T copy-mode-vi v send-keys -X begin-selection
          bind-key -T copy-mode-vi y send-keys -X copy-selection

          # Don't cancel copy mode on mouse selection
          bind -T copy-mode MouseDragEnd1Pane send -X copy-selection
          bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-selection

          # Don't start a login shell
          set -g default-command "''${SHELL}"

          # Show session selector (default to showing only unattached sessions)
          bind-key s choose-tree -sZ -f '#{?session_attached,0,1}'

          # Tmux window names
          set-option -g automatic-rename on
          set-option -g automatic-rename-format '#{pane_title}'

          # Terminal window names
          set-option -g set-titles on
          set-option -g set-titles-string '#{window_name}'

          # Clipboard integration
          set-option -g set-clipboard external

          # XXX GPG env vars?
          set-option -g update-environment 'DISPLAY SSH_ASKPASS SSH_AUTH_SOCK SSH_AGENT_PID SSH_CONNECTION WINDOWID XAUTHORITY TERM'

          # Set the RGB capability if the environment variable COLORTERM is truecolor or 24 bit
          # https://github.com/tmux/tmux/issues/4300#issuecomment-2967808922
          %if "#{==:#{COLORTERM},truecolor}"
            set -as terminal-features ",*-:RGB"
          %elif "#{==:#{COLORTERM},24bit}"
            set -as terminal-features ",*-:RGB"
          %endif
        '';

        plugins = with pkgs.tmuxPlugins; [
          pain-control
          nord
          {
            plugin = mighty-scroll;
            extraConfig = ''
              set -g @mighty-scroll-interval 3
              set -g @mighty-scroll-show-indicator on
              set -g @mighty-scroll-select-pane off
            '';
          }
          {
            plugin = tmux-which-key.overrideAttrs (oldAttrs: {
              configYaml = lib.generators.toYAML { } {
                # The starting index to use for the command-alias option, used for macros
                # (required). This value must be at least 200
                command_alias_start_index = 200;
                # The keybindings that open the action menu (required)
                keybindings = {
                  prefix_table = "Space"; # The keybinding for the prefix key table (required)
                  root_table = "C-Space"; # The keybinding for the root key table (optional)
                };
                # The menu title config (optional)
                title = {
                  style = "align=centre,bold"; # The title style
                  prefix = "tmux"; # A prefix added to every menu title
                  prefix_style = "fg=green,align=centre,bold"; # The prefix style
                };
                # The menu position (optional)
                position = {
                  x = "R";
                  y = "P";
                };
                # The root menu items (required)
                items = [
                  {
                    name = "Next pane";
                    key = "space"; # The key that triggers this action
                    command = "next-pane"; # A command to run
                  }
                  {
                    name = "Respawn pane";
                    key = "R";
                    macro = "restart-pane"; # A custom macro (defined above)
                  }
                  {
                    separator = true; # A menu separator
                  }
                  {
                    name = "+Layout"; # A submenu
                    key = "l";
                    # The submenu items
                    menu = [
                      {
                        name = "Next";
                        key = "l";
                        command = "nextl";
                        transient = true; # Whether to keep the menu open until ESC is pressed
                      }
                    ];
                  }
                ];
              };
              passAsFile = (oldAttrs.passAsFile or [ ]) ++ [ "configYaml" ];
              preInstall = (oldAttrs.preInstall or "") + ''
                mkdir -p $out/plugin
                cp $configYamlPath $out/plugin/config.yaml
              '';
            });
            extraConfig = ''
              set -g @tmux-which-key-disable-autobuild 1
            '';
          }
          {
            plugin = transient-status;
            extraConfig = ''
              set-option -g status 'off'
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
      waybar = {
        enable = true;
        systemd.enable = true;
        settings = {
          mainBar = {
            layer = "top";
            position = "top";
            modules-left = [
              "clock"
            ];
            modules-center = [
            ];
            modules-right = [
              "pulseaudio"
              "cpu"
              "memory"
              "network"
              "idle_inhibitor"
              "tray"
            ];
            idle_inhibitor = {
              format = "{icon}";
              format-icons = {
                activated = " ";
                deactivated = " ";
              };
              tooltip = true;
            };
            tray = {
              spacing = 5;
            };
            clock = {
              format = "  {:%H:%M    %e %b}";
              tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
              today-format = "<b>{}</b>";
              on-click = "gnome-calendar";
            };
            cpu = {
              interval = 1;
              format = "  {max_frequency}GHz <span color=\"darkgray\">| {usage}%</span>";
              on-click = "kitty -e htop --sort-key PERCENT_CPU";
              tooltip = false;
            };
            memory = {
              interval = 1;
              format = "  {}%";
              on-click = "kitty -e htop --sort-key PERCENT_MEM";
              tooltip = false;
            };
            network = {
              format-wifi = " {essid}";
              format-ethernet = "{ifname}: {ipaddr}/{cidr}  ";
              format-linked = "{ifname} (No IP) 󰈁 ";
              format-disconnected = "󰈂 ";
              format-alt = "{ifname}: {ipaddr}/{cidr}";
              family = "ipv4";
              tooltip-format-wifi = "  {ifname} @ {essid}\n󰩟  {ipaddr}\nStrength: {signalStrength}%\n  {frequency}MHz\n  {bandwidthUpBits}   {bandwidthDownBits}";
              tooltip-format-ethernet = "  {ifname}\n󰩟  {ipaddr}\n  {bandwidthUpBits}   {bandwidthDownBits}";
            };
            pulseaudio = {
              scroll-step = 3;
              format = "{icon} {volume}% {format_source}";
              format-bluetooth = "{volume}% {icon}  {format_source}";
              format-bluetooth-muted = "󰖁  {icon}  {format_source}";
              format-muted = "󰖁  {format_source}";
              format-source = " ";
              format-source-muted = " ";
              format-icons = {
                headphone = " ";
                hands-free = "󱡏 ";
                headset = " ";
                phone = " ";
                portable = " ";
                car = " ";
                default = [
                  " "
                  " "
                  " "
                ];
              };
              on-click = "pavucontrol";
              on-click-right = "pactl set-source-mute @DEFAULT_SOURCE@ toggle";
            };
          };
        };
        style = ''
          @keyframes blink-warning {
            70% {
              color: @light;
            }

            to {
              color: @light;
              background-color: @warning;
            }
          }

          @keyframes blink-critical {
            70% {
            color: @light;
            }

            to {
              color: @light;
              background-color: @critical;
            }
          }


          /* -----------------------------------------------------------------------------
           * Styles
           * -------------------------------------------------------------------------- */

          /* COLORS */

          /* Nord */
          @define-color bg #2E3440;
          @define-color light @nord_light_font;
          @define-color dark @nord_dark_font;
          @define-color warning #ebcb8b;
          @define-color critical #BF616A;
          @define-color mode #434C5E;
          @define-color workspaces @bg;
          @define-color workspacesfocused #4C566A;
          @define-color tray @workspacesfocused;
          @define-color sound #EBCB8B;
          @define-color network #5D7096;
          @define-color memory #546484;
          @define-color cpu #596A8D;
          @define-color temp #4D5C78;
          @define-color layout #5e81ac;
          @define-color battery #88c0d0;
          @define-color date #434C5E;
          @define-color time #434C5E;
          @define-color backlight #434C5E;
          @define-color nord_bg #434C5E;
          @define-color nord_bg_blue #546484;
          @define-color nord_light #D8DEE9;
          @define-color nord_light_font #D8DEE9;
          @define-color nord_dark_font #434C5E;

          /* Reset all styles */
          * {
            border: none;
            border-radius: 3px;
            min-height: 0;
            margin: 0.1em;
          }

          /* The whole bar */
          #waybar {
            background: @bg;
            color: @light;
            font-family: "Iosevka Nerd Font";
            font-size: 12px;
            font-weight: bold;
          }

          /* Each module */
          #battery,
          #clock,
          #cpu,
          #memory,
          #submap,
          #network,
          #pulseaudio,
          #tray,
          #backlight,
          #idle_indicator,
          #language {
            padding-left: 0.5em;
            padding-right: 0.5em;
          }

          /* Each module that should blink */
          #submap,
          #memory,
          #temperature,
          #battery {
            animation-timing-function: linear;
            animation-iteration-count: infinite;
            animation-direction: alternate;
          }

          /* Each critical module */
          #memory.critical,
          #cpu.critical,
          #temperature.critical,
          #battery.critical {
            color: @critical;
          }

          /* Each critical that should blink */
          #submap,
          #memory.critical,
          #temperature.critical,
          #battery.critical.discharging {
            animation-name: blink-critical;
            animation-duration: 2s;
          }

          /* Each warning */
          #network.disconnected,
          #memory.warning,
          #cpu.warning,
          #temperature.warning,
          #battery.warning {
            background: @warning;
            color: @nord_dark_font;
          }

          /* Each warning that should blink */
          #battery.warning.discharging {
            animation-name: blink-warning;
            animation-duration: 3s;
          }

          /* And now modules themselves in their respective order */

          #submap { /* Shown current WM submap (resize etc.) */
            color: @light;
            background: @mode;
          }

          /* Workspaces stuff */

          #workspaces {
            background: @bg;
            color: @light;
          }

          #workspaces button {
            font-weight: bold; /* Somewhy the bar-wide setting is ignored*/
            padding: 0;
            opacity: 0.3;
            background: none;
            font-size: 1em;
          }

          #workspaces button.active {
            background: @workspacesfocused;
            color: #D8DEE9;
            opacity: 1;
            padding: 0 0.4em;
          }

          #workspaces button.urgent {
            border-color: #c9545d;
            color: #c9545d;
            opacity: 1;
          }

          #window {
            margin: 0 0.6em;
            font-weight: normal;
          }

          #idle_inhibitor {
            background: @mode;
            /*font-size: 1.6em;*/
            font-weight: bold;
            padding: 0 0.4em;
          }

          #network {
            background: @nord_bg_blue;
          }

          #memory {
            background: @nord_bg;
            color: #D8DEE9;
          }
          #memory.critical {
            color: @nord_dark_font;
          }

          #cpu {
            background: @nord_bg;
            color: #D8DEE9;
          }
          #cpu.critical {
            color: @nord_dark_font;
          }
          #language {
            background: @nord_bg_blue;
            color: #D8DEE9;
            padding: 0 0.4em;
          }
          #battery {
            background: @battery;
          }
          #backlight {
            background: @backlight;
          }
          #clock {
            background: @nord_bg_blue;
            color: #D8DEE9;
          }
          #clock.date {
            background: @date;
          }
          #clock.time {
            background: @mode;
          }
          #pulseaudio { /* Unsused but kept for those who needs it */
            background: @nord_bg_blue;
            color: #D8DEE9;
          }
          #pulseaudio.muted {
            background: #BF616A;
            color: #BF616A;
            /* No styles */
          }
          #pulseaudio.source-muted {
            background: #D08770;
            color: #D8DEE9;
            /* No styles */
          }
          #tray {
            background: #434C5E;
          }
        '';
      };
      zathura = {
        enable = true;
        package = pkgs.zathura.override { useMupdf = true; };
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

          # Database
          database = "sqlite";
        };
      };
      # niri = {
      #   settings = {
      #     input = {
      #       keyboard = {
      #         xkb = {
      #           layout = "us,us";
      #           variant = "dvp,";
      #           options = "grp:win_space_toggle,shift:both_capslock,compose:ralt";
      #         };
      #         numlock = true;
      #       };
      #       touchpad = {
      #         tap = true;
      #         dwt = true;
      #         dwtp = true;
      #         drag = true;
      #         drag-lock = true;
      #         natural-scroll = true;
      #         accel-speed = 0.2;
      #         accel-profile = "flat";
      #         scroll-method = "two-finger";
      #         tap-button-map = "left-right-middle";
      #       };
      #       mouse = {
      #         accel-speed = 0.2;
      #         accel-profile = "flat";
      #         scroll-method = "no-scroll";
      #       };
      #       disable-power-key-handling = true;
      #       warp-mouse-to-focus = true;
      #       focus-follows-mouse = true;
      #       workspace-auto-back-and-forth = true;
      #     };
      #     # // You can configure outputs by their name, which you can find
      #     # // by running `niri msg outputs` while inside a niri instance.
      #     # // The built-in laptop monitor is usually called "eDP-1".
      #     # // Find more information on the wiki:
      #     # // https://yalter.github.io/niri/Configuration:-Outputs
      #     # // Remember to uncomment the node by removing "/-"!
      #     # /-output "eDP-1" {
      #     #     // Uncomment this line to disable this output.
      #     #     // off

      #     #     // Resolution and, optionally, refresh rate of the output.
      #     #     // The format is "<width>x<height>" or "<width>x<height>@<refresh rate>".
      #     #     // If the refresh rate is omitted, niri will pick the highest refresh rate
      #     #     // for the resolution.
      #     #     // If the mode is omitted altogether or is invalid, niri will pick one automatically.
      #     #     // Run `niri msg outputs` while inside a niri instance to list all outputs and their modes.
      #     #     mode "1920x1080@120.030"

      #     #     // You can use integer or fractional scale, for example use 1.5 for 150% scale.
      #     #     scale 2

      #     #     // Transform allows to rotate the output counter-clockwise, valid values are:
      #     #     // normal, 90, 180, 270, flipped, flipped-90, flipped-180 and flipped-270.
      #     #     transform "normal"

      #     #     // Position of the output in the global coordinate space.
      #     #     // This affects directional monitor actions like "focus-monitor-left", and cursor movement.
      #     #     // The cursor can only move between directly adjacent outputs.
      #     #     // Output scale and rotation has to be taken into account for positioning:
      #     #     // outputs are sized in logical, or scaled, pixels.
      #     #     // For example, a 3840×2160 output with scale 2.0 will have a logical size of 1920×1080,
      #     #     // so to put another output directly adjacent to it on the right, set its x to 1920.
      #     #     // If the position is unset or results in an overlap, the output is instead placed
      #     #     // automatically.
      #     #     position x=1280 y=0
      #     # }

      #     # // Settings that influence how windows are positioned and sized.
      #     # // Find more information on the wiki:
      #     # // https://yalter.github.io/niri/Configuration:-Layout
      #     # layout {
      #     #     // Set gaps around windows in logical pixels.
      #     #     gaps 16

      #     #     // When to center a column when changing focus, options are:
      #     #     // - "never", default behavior, focusing an off-screen column will keep at the left
      #     #     //   or right edge of the screen.
      #     #     // - "always", the focused column will always be centered.
      #     #     // - "on-overflow", focusing a column will center it if it doesn't fit
      #     #     //   together with the previously focused column.
      #     #     center-focused-column "never"

      #     #     // You can customize the widths that "switch-preset-column-width" (Mod+R) toggles between.
      #     #     preset-column-widths {
      #     #         // Proportion sets the width as a fraction of the output width, taking gaps into account.
      #     #         // For example, you can perfectly fit four windows sized "proportion 0.25" on an output.
      #     #         // The default preset widths are 1/3, 1/2 and 2/3 of the output.
      #     #         proportion 0.33333
      #     #         proportion 0.5
      #     #         proportion 0.66667

      #     #         // Fixed sets the width in logical pixels exactly.
      #     #         // fixed 1920
      #     #     }

      #     #     // You can also customize the heights that "switch-preset-window-height" (Mod+Shift+R) toggles between.
      #     #     // preset-window-heights { }

      #     #     // You can change the default width of the new windows.
      #     #     default-column-width { proportion 0.5; }
      #     #     // If you leave the brackets empty, the windows themselves will decide their initial width.
      #     #     // default-column-width {}

      #     #     // By default focus ring and border are rendered as a solid background rectangle
      #     #     // behind windows. That is, they will show up through semitransparent windows.
      #     #     // This is because windows using client-side decorations can have an arbitrary shape.
      #     #     //
      #     #     // If you don't like that, you should uncomment `prefer-no-csd` below.
      #     #     // Niri will draw focus ring and border *around* windows that agree to omit their
      #     #     // client-side decorations.
      #     #     //
      #     #     // Alternatively, you can override it with a window rule called
      #     #     // `draw-border-with-background`.

      #     #     // You can change how the focus ring looks.
      #     #     focus-ring {
      #     #         // Uncomment this line to disable the focus ring.
      #     #         // off

      #     #         // How many logical pixels the ring extends out from the windows.
      #     #         width 4

      #     #         // Colors can be set in a variety of ways:
      #     #         // - CSS named colors: "red"
      #     #         // - RGB hex: "#rgb", "#rgba", "#rrggbb", "#rrggbbaa"
      #     #         // - CSS-like notation: "rgb(255, 127, 0)", rgba(), hsl() and a few others.

      #     #         // Color of the ring on the active monitor.
      #     #         active-color "#7fc8ff"

      #     #         // Color of the ring on inactive monitors.
      #     #         //
      #     #         // The focus ring only draws around the active window, so the only place
      #     #         // where you can see its inactive-color is on other monitors.
      #     #         inactive-color "#505050"

      #     #         // You can also use gradients. They take precedence over solid colors.
      #     #         // Gradients are rendered the same as CSS linear-gradient(angle, from, to).
      #     #         // The angle is the same as in linear-gradient, and is optional,
      #     #         // defaulting to 180 (top-to-bottom gradient).
      #     #         // You can use any CSS linear-gradient tool on the web to set these up.
      #     #         // Changing the color space is also supported, check the wiki for more info.
      #     #         //
      #     #         // active-gradient from="#80c8ff" to="#c7ff7f" angle=45

      #     #         // You can also color the gradient relative to the entire view
      #     #         // of the workspace, rather than relative to just the window itself.
      #     #         // To do that, set relative-to="workspace-view".
      #     #         //
      #     #         // inactive-gradient from="#505050" to="#808080" angle=45 relative-to="workspace-view"
      #     #     }

      #     #     // You can also add a border. It's similar to the focus ring, but always visible.
      #     #     border {
      #     #         // The settings are the same as for the focus ring.
      #     #         // If you enable the border, you probably want to disable the focus ring.
      #     #         off

      #     #         width 4
      #     #         active-color "#ffc87f"
      #     #         inactive-color "#505050"

      #     #         // Color of the border around windows that request your attention.
      #     #         urgent-color "#9b0000"

      #     #         // Gradients can use a few different interpolation color spaces.
      #     #         // For example, this is a pastel rainbow gradient via in="oklch longer hue".
      #     #         //
      #     #         // active-gradient from="#e5989b" to="#ffb4a2" angle=45 relative-to="workspace-view" in="oklch longer hue"

      #     #         // inactive-gradient from="#505050" to="#808080" angle=45 relative-to="workspace-view"
      #     #     }

      #     #     // You can enable drop shadows for windows.
      #     #     shadow {
      #     #         // Uncomment the next line to enable shadows.
      #     #         // on

      #     #         // By default, the shadow draws only around its window, and not behind it.
      #     #         // Uncomment this setting to make the shadow draw behind its window.
      #     #         //
      #     #         // Note that niri has no way of knowing about the CSD window corner
      #     #         // radius. It has to assume that windows have square corners, leading to
      #     #         // shadow artifacts inside the CSD rounded corners. This setting fixes
      #     #         // those artifacts.
      #     #         //
      #     #         // However, instead you may want to set prefer-no-csd and/or
      #     #         // geometry-corner-radius. Then, niri will know the corner radius and
      #     #         // draw the shadow correctly, without having to draw it behind the
      #     #         // window. These will also remove client-side shadows if the window
      #     #         // draws any.
      #     #         //
      #     #         // draw-behind-window true

      #     #         // You can change how shadows look. The values below are in logical
      #     #         // pixels and match the CSS box-shadow properties.

      #     #         // Softness controls the shadow blur radius.
      #     #         softness 30

      #     #         // Spread expands the shadow.
      #     #         spread 5

      #     #         // Offset moves the shadow relative to the window.
      #     #         offset x=0 y=5

      #     #         // You can also change the shadow color and opacity.
      #     #         color "#0007"
      #     #     }

      #     #     // Struts shrink the area occupied by windows, similarly to layer-shell panels.
      #     #     // You can think of them as a kind of outer gaps. They are set in logical pixels.
      #     #     // Left and right struts will cause the next window to the side to always be visible.
      #     #     // Top and bottom struts will simply add outer gaps in addition to the area occupied by
      #     #     // layer-shell panels and regular gaps.
      #     #     struts {
      #     #         // left 64
      #     #         // right 64
      #     #         // top 64
      #     #         // bottom 64
      #     #     }
      #     # }

      #     # // Add lines like this to spawn processes at startup.
      #     # // Note that running niri as a session supports xdg-desktop-autostart,
      #     # // which may be more convenient to use.
      #     # // See the binds section below for more spawn examples.

      #     # // This line starts waybar, a commonly used bar for Wayland compositors.
      #     # spawn-at-startup "waybar"

      #     # // To run a shell command (with variables, pipes, etc.), use spawn-sh-at-startup:
      #     # // spawn-sh-at-startup "qs -c ~/source/qs/MyAwesomeShell"

      #     # hotkey-overlay {
      #     #     // Uncomment this line to disable the "Important Hotkeys" pop-up at startup.
      #     #     // skip-at-startup
      #     # }

      #     # // Uncomment this line to ask the clients to omit their client-side decorations if possible.
      #     # // If the client will specifically ask for CSD, the request will be honored.
      #     # // Additionally, clients will be informed that they are tiled, removing some client-side rounded corners.
      #     # // This option will also fix border/focus ring drawing behind some semitransparent windows.
      #     # // After enabling or disabling this, you need to restart the apps for this to take effect.
      #     # // prefer-no-csd

      #     # // You can change the path where screenshots are saved.
      #     # // A ~ at the front will be expanded to the home directory.
      #     # // The path is formatted with strftime(3) to give you the screenshot date and time.
      #     # screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

      #     # // You can also set this to null to disable saving screenshots to disk.
      #     # // screenshot-path null

      #     # // Animation settings.
      #     # // The wiki explains how to configure individual animations:
      #     # // https://yalter.github.io/niri/Configuration:-Animations
      #     # animations {
      #     #     // Uncomment to turn off all animations.
      #     #     // off

      #     #     // Slow down all animations by this factor. Values below 1 speed them up instead.
      #     #     // slowdown 3.0
      #     # }

      #     # // Window rules let you adjust behavior for individual windows.
      #     # // Find more information on the wiki:
      #     # // https://yalter.github.io/niri/Configuration:-Window-Rules

      #     # // Work around WezTerm's initial configure bug
      #     # // by setting an empty default-column-width.
      #     # window-rule {
      #     #     // This regular expression is intentionally made as specific as possible,
      #     #     // since this is the default config, and we want no false positives.
      #     #     // You can get away with just app-id="wezterm" if you want.
      #     #     match app-id=r#"^org\.wezfurlong\.wezterm$"#
      #     #     default-column-width {}
      #     # }

      #     # // Open the Firefox picture-in-picture player as floating by default.
      #     # window-rule {
      #     #     // This app-id regular expression will work for both:
      #     #     // - host Firefox (app-id is "firefox")
      #     #     // - Flatpak Firefox (app-id is "org.mozilla.firefox")
      #     #     match app-id=r#"firefox$"# title="^Picture-in-Picture$"
      #     #     open-floating true
      #     # }

      #     # // Example: block out two password managers from screen capture.
      #     # // (This example rule is commented out with a "/-" in front.)
      #     # /-window-rule {
      #     #     match app-id=r#"^org\.keepassxc\.KeePassXC$"#
      #     #     match app-id=r#"^org\.gnome\.World\.Secrets$"#

      #     #     block-out-from "screen-capture"

      #     #     // Use this instead if you want them visible on third-party screenshot tools.
      #     #     // block-out-from "screencast"
      #     # }

      #     # // Example: enable rounded corners for all windows.
      #     # // (This example rule is commented out with a "/-" in front.)
      #     # /-window-rule {
      #     #     geometry-corner-radius 12
      #     #     clip-to-geometry true
      #     # }

      #     # binds {
      #     #     // Keys consist of modifiers separated by + signs, followed by an XKB key name
      #     #     // in the end. To find an XKB name for a particular key, you may use a program
      #     #     // like wev.
      #     #     //
      #     #     // "Mod" is a special modifier equal to Super when running on a TTY, and to Alt
      #     #     // when running as a winit window.
      #     #     //
      #     #     // Most actions that you can bind here can also be invoked programmatically with
      #     #     // `niri msg action do-something`.

      #     #     // Mod-Shift-/, which is usually the same as Mod-?,
      #     #     // shows a list of important hotkeys.
      #     #     Mod+Shift+Slash { show-hotkey-overlay; }

      #     #     // Suggested binds for running programs: terminal, app launcher, screen locker.
      #     #     Mod+T hotkey-overlay-title="Open a Terminal: alacritty" { spawn "alacritty"; }
      #     #     Mod+D hotkey-overlay-title="Run an Application: fuzzel" { spawn "fuzzel"; }
      #     #     Super+Alt+L hotkey-overlay-title="Lock the Screen: swaylock" { spawn "swaylock"; }

      #     #     // Use spawn-sh to run a shell command. Do this if you need pipes, multiple commands, etc.
      #     #     // Note: the entire command goes as a single argument. It's passed verbatim to `sh -c`.
      #     #     // For example, this is a standard bind to toggle the screen reader (orca).
      #     #     Super+Alt+S allow-when-locked=true hotkey-overlay-title=null { spawn-sh "pkill orca || exec orca"; }

      #     #     // Example volume keys mappings for PipeWire & WirePlumber.
      #     #     // The allow-when-locked=true property makes them work even when the session is locked.
      #     #     // Using spawn-sh allows to pass multiple arguments together with the command.
      #     #     XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+"; }
      #     #     XF86AudioLowerVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-"; }
      #     #     XF86AudioMute        allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; }
      #     #     XF86AudioMicMute     allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"; }

      #     #     // Example brightness key mappings for brightnessctl.
      #     #     // You can use regular spawn with multiple arguments too (to avoid going through "sh"),
      #     #     // but you need to manually put each argument in separate "" quotes.
      #     #     XF86MonBrightnessUp allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "+10%"; }
      #     #     XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "10%-"; }

      #     #     // Open/close the Overview: a zoomed-out view of workspaces and windows.
      #     #     // You can also move the mouse into the top-left hot corner,
      #     #     // or do a four-finger swipe up on a touchpad.
      #     #     Mod+O repeat=false { toggle-overview; }

      #     #     Mod+Q repeat=false { close-window; }

      #     #     Mod+Left  { focus-column-left; }
      #     #     Mod+Down  { focus-window-down; }
      #     #     Mod+Up    { focus-window-up; }
      #     #     Mod+Right { focus-column-right; }
      #     #     Mod+H     { focus-column-left; }
      #     #     Mod+J     { focus-window-down; }
      #     #     Mod+K     { focus-window-up; }
      #     #     Mod+L     { focus-column-right; }

      #     #     Mod+Ctrl+Left  { move-column-left; }
      #     #     Mod+Ctrl+Down  { move-window-down; }
      #     #     Mod+Ctrl+Up    { move-window-up; }
      #     #     Mod+Ctrl+Right { move-column-right; }
      #     #     Mod+Ctrl+H     { move-column-left; }
      #     #     Mod+Ctrl+J     { move-window-down; }
      #     #     Mod+Ctrl+K     { move-window-up; }
      #     #     Mod+Ctrl+L     { move-column-right; }

      #     #     // Alternative commands that move across workspaces when reaching
      #     #     // the first or last window in a column.
      #     #     // Mod+J     { focus-window-or-workspace-down; }
      #     #     // Mod+K     { focus-window-or-workspace-up; }
      #     #     // Mod+Ctrl+J     { move-window-down-or-to-workspace-down; }
      #     #     // Mod+Ctrl+K     { move-window-up-or-to-workspace-up; }

      #     #     Mod+Home { focus-column-first; }
      #     #     Mod+End  { focus-column-last; }
      #     #     Mod+Ctrl+Home { move-column-to-first; }
      #     #     Mod+Ctrl+End  { move-column-to-last; }

      #     #     Mod+Shift+Left  { focus-monitor-left; }
      #     #     Mod+Shift+Down  { focus-monitor-down; }
      #     #     Mod+Shift+Up    { focus-monitor-up; }
      #     #     Mod+Shift+Right { focus-monitor-right; }
      #     #     Mod+Shift+H     { focus-monitor-left; }
      #     #     Mod+Shift+J     { focus-monitor-down; }
      #     #     Mod+Shift+K     { focus-monitor-up; }
      #     #     Mod+Shift+L     { focus-monitor-right; }

      #     #     Mod+Shift+Ctrl+Left  { move-column-to-monitor-left; }
      #     #     Mod+Shift+Ctrl+Down  { move-column-to-monitor-down; }
      #     #     Mod+Shift+Ctrl+Up    { move-column-to-monitor-up; }
      #     #     Mod+Shift+Ctrl+Right { move-column-to-monitor-right; }
      #     #     Mod+Shift+Ctrl+H     { move-column-to-monitor-left; }
      #     #     Mod+Shift+Ctrl+J     { move-column-to-monitor-down; }
      #     #     Mod+Shift+Ctrl+K     { move-column-to-monitor-up; }
      #     #     Mod+Shift+Ctrl+L     { move-column-to-monitor-right; }

      #     #     // Alternatively, there are commands to move just a single window:
      #     #     // Mod+Shift+Ctrl+Left  { move-window-to-monitor-left; }
      #     #     // ...

      #     #     // And you can also move a whole workspace to another monitor:
      #     #     // Mod+Shift+Ctrl+Left  { move-workspace-to-monitor-left; }
      #     #     // ...

      #     #     Mod+Page_Down      { focus-workspace-down; }
      #     #     Mod+Page_Up        { focus-workspace-up; }
      #     #     Mod+U              { focus-workspace-down; }
      #     #     Mod+I              { focus-workspace-up; }
      #     #     Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
      #     #     Mod+Ctrl+Page_Up   { move-column-to-workspace-up; }
      #     #     Mod+Ctrl+U         { move-column-to-workspace-down; }
      #     #     Mod+Ctrl+I         { move-column-to-workspace-up; }

      #     #     // Alternatively, there are commands to move just a single window:
      #     #     // Mod+Ctrl+Page_Down { move-window-to-workspace-down; }
      #     #     // ...

      #     #     Mod+Shift+Page_Down { move-workspace-down; }
      #     #     Mod+Shift+Page_Up   { move-workspace-up; }
      #     #     Mod+Shift+U         { move-workspace-down; }
      #     #     Mod+Shift+I         { move-workspace-up; }

      #     #     // You can bind mouse wheel scroll ticks using the following syntax.
      #     #     // These binds will change direction based on the natural-scroll setting.
      #     #     //
      #     #     // To avoid scrolling through workspaces really fast, you can use
      #     #     // the cooldown-ms property. The bind will be rate-limited to this value.
      #     #     // You can set a cooldown on any bind, but it's most useful for the wheel.
      #     #     Mod+WheelScrollDown      cooldown-ms=150 { focus-workspace-down; }
      #     #     Mod+WheelScrollUp        cooldown-ms=150 { focus-workspace-up; }
      #     #     Mod+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
      #     #     Mod+Ctrl+WheelScrollUp   cooldown-ms=150 { move-column-to-workspace-up; }

      #     #     Mod+WheelScrollRight      { focus-column-right; }
      #     #     Mod+WheelScrollLeft       { focus-column-left; }
      #     #     Mod+Ctrl+WheelScrollRight { move-column-right; }
      #     #     Mod+Ctrl+WheelScrollLeft  { move-column-left; }

      #     #     // Usually scrolling up and down with Shift in applications results in
      #     #     // horizontal scrolling; these binds replicate that.
      #     #     Mod+Shift+WheelScrollDown      { focus-column-right; }
      #     #     Mod+Shift+WheelScrollUp        { focus-column-left; }
      #     #     Mod+Ctrl+Shift+WheelScrollDown { move-column-right; }
      #     #     Mod+Ctrl+Shift+WheelScrollUp   { move-column-left; }

      #     #     // Similarly, you can bind touchpad scroll "ticks".
      #     #     // Touchpad scrolling is continuous, so for these binds it is split into
      #     #     // discrete intervals.
      #     #     // These binds are also affected by touchpad's natural-scroll, so these
      #     #     // example binds are "inverted", since we have natural-scroll enabled for
      #     #     // touchpads by default.
      #     #     // Mod+TouchpadScrollDown { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.02+"; }
      #     #     // Mod+TouchpadScrollUp   { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.02-"; }

      #     #     // You can refer to workspaces by index. However, keep in mind that
      #     #     // niri is a dynamic workspace system, so these commands are kind of
      #     #     // "best effort". Trying to refer to a workspace index bigger than
      #     #     // the current workspace count will instead refer to the bottommost
      #     #     // (empty) workspace.
      #     #     //
      #     #     // For example, with 2 workspaces + 1 empty, indices 3, 4, 5 and so on
      #     #     // will all refer to the 3rd workspace.
      #     #     Mod+1 { focus-workspace 1; }
      #     #     Mod+2 { focus-workspace 2; }
      #     #     Mod+3 { focus-workspace 3; }
      #     #     Mod+4 { focus-workspace 4; }
      #     #     Mod+5 { focus-workspace 5; }
      #     #     Mod+6 { focus-workspace 6; }
      #     #     Mod+7 { focus-workspace 7; }
      #     #     Mod+8 { focus-workspace 8; }
      #     #     Mod+9 { focus-workspace 9; }
      #     #     Mod+Ctrl+1 { move-column-to-workspace 1; }
      #     #     Mod+Ctrl+2 { move-column-to-workspace 2; }
      #     #     Mod+Ctrl+3 { move-column-to-workspace 3; }
      #     #     Mod+Ctrl+4 { move-column-to-workspace 4; }
      #     #     Mod+Ctrl+5 { move-column-to-workspace 5; }
      #     #     Mod+Ctrl+6 { move-column-to-workspace 6; }
      #     #     Mod+Ctrl+7 { move-column-to-workspace 7; }
      #     #     Mod+Ctrl+8 { move-column-to-workspace 8; }
      #     #     Mod+Ctrl+9 { move-column-to-workspace 9; }

      #     #     // Alternatively, there are commands to move just a single window:
      #     #     // Mod+Ctrl+1 { move-window-to-workspace 1; }

      #     #     // Switches focus between the current and the previous workspace.
      #     #     // Mod+Tab { focus-workspace-previous; }

      #     #     // The following binds move the focused window in and out of a column.
      #     #     // If the window is alone, they will consume it into the nearby column to the side.
      #     #     // If the window is already in a column, they will expel it out.
      #     #     Mod+BracketLeft  { consume-or-expel-window-left; }
      #     #     Mod+BracketRight { consume-or-expel-window-right; }

      #     #     // Consume one window from the right to the bottom of the focused column.
      #     #     Mod+Comma  { consume-window-into-column; }
      #     #     // Expel the bottom window from the focused column to the right.
      #     #     Mod+Period { expel-window-from-column; }

      #     #     Mod+R { switch-preset-column-width; }
      #     #     // Cycling through the presets in reverse order is also possible.
      #     #     // Mod+R { switch-preset-column-width-back; }
      #     #     Mod+Shift+R { switch-preset-window-height; }
      #     #     Mod+Ctrl+R { reset-window-height; }
      #     #     Mod+F { maximize-column; }
      #     #     Mod+Shift+F { fullscreen-window; }

      #     #     // Expand the focused column to space not taken up by other fully visible columns.
      #     #     // Makes the column "fill the rest of the space".
      #     #     Mod+Ctrl+F { expand-column-to-available-width; }

      #     #     Mod+C { center-column; }

      #     #     // Center all fully visible columns on screen.
      #     #     Mod+Ctrl+C { center-visible-columns; }

      #     #     // Finer width adjustments.
      #     #     // This command can also:
      #     #     // * set width in pixels: "1000"
      #     #     // * adjust width in pixels: "-5" or "+5"
      #     #     // * set width as a percentage of screen width: "25%"
      #     #     // * adjust width as a percentage of screen width: "-10%" or "+10%"
      #     #     // Pixel sizes use logical, or scaled, pixels. I.e. on an output with scale 2.0,
      #     #     // set-column-width "100" will make the column occupy 200 physical screen pixels.
      #     #     Mod+Minus { set-column-width "-10%"; }
      #     #     Mod+Equal { set-column-width "+10%"; }

      #     #     // Finer height adjustments when in column with other windows.
      #     #     Mod+Shift+Minus { set-window-height "-10%"; }
      #     #     Mod+Shift+Equal { set-window-height "+10%"; }

      #     #     // Move the focused window between the floating and the tiling layout.
      #     #     Mod+V       { toggle-window-floating; }
      #     #     Mod+Shift+V { switch-focus-between-floating-and-tiling; }

      #     #     // Toggle tabbed column display mode.
      #     #     // Windows in this column will appear as vertical tabs,
      #     #     // rather than stacked on top of each other.
      #     #     Mod+W { toggle-column-tabbed-display; }

      #     #     // Actions to switch layouts.
      #     #     // Note: if you uncomment these, make sure you do NOT have
      #     #     // a matching layout switch hotkey configured in xkb options above.
      #     #     // Having both at once on the same hotkey will break the switching,
      #     #     // since it will switch twice upon pressing the hotkey (once by xkb, once by niri).
      #     #     // Mod+Space       { switch-layout "next"; }
      #     #     // Mod+Shift+Space { switch-layout "prev"; }

      #     #     Print { screenshot; }
      #     #     Ctrl+Print { screenshot-screen; }
      #     #     Alt+Print { screenshot-window; }

      #     #     // Applications such as remote-desktop clients and software KVM switches may
      #     #     // request that niri stops processing the keyboard shortcuts defined here
      #     #     // so they may, for example, forward the key presses as-is to a remote machine.
      #     #     // It's a good idea to bind an escape hatch to toggle the inhibitor,
      #     #     // so a buggy application can't hold your session hostage.
      #     #     //
      #     #     // The allow-inhibiting=false property can be applied to other binds as well,
      #     #     // which ensures niri always processes them, even when an inhibitor is active.
      #     #     Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }

      #     #     // The quit action will show a confirmation dialog to avoid accidental exits.
      #     #     Mod+Shift+E { quit; }
      #     #     Ctrl+Alt+Delete { quit; }

      #     #     // Powers off the monitors. To turn them back on, do any input like
      #     #     // moving the mouse or pressing any other key.
      #     #     Mod+Shift+P { power-off-monitors; }
      #     # }
      #   };
      # };
    };

    services = {
      blueman-applet.enable = true;
      darkman = {
        enable = true;
        settings = {
          lat = -26.2;
          lng = 28.0;
          usegeoclue = true;
          dbusserver = true;
          portal = true;
        };
      };
      dunst = {
        enable = true;
        settings = {
          global = {
            follow = "keyboard";
            width = "(0, 500)";
            height = 100;
            offset = "24x48";
            separator_height = 4;
            frame_width = 0;
            separator_color = "#00000000";
            font = "Iosevka Nerd Font 10";
            format = "<b>%s</b>\\n%b";
            vertical_alignment = "top";
            show_age_threshold = "5m";
            icon_position = "left";
            max_icon_size = 60;
            icon_path = "${pkgs.zafiro-icons}/share/icons/Zafiro-icons";
            enable_recursive_icon_lookup = "true";
            dmenu = "${config.programs.rofi.package}/bin/rofi -dmenu -p dunst";
            mouse_left_click = "close_current";
            mouse_middle_click = "context";
            mouse_right_click = "do_action";
            fullscreen = "pushback";
            timeout = "30s";
            markup = "full";
            foreground = colors.nord6;
          };
          urgency_low = {
            background = "${colors.nord3}99";
          };
          urgency_normal = {
            background = "${colors.nord10}99";
          };
          urgency_critical = {
            background = "${colors.nord11}99";
            fullscreen = "show";
            timeout = 0;
          };
        };
      };
      flameshot = {
        enable = true;
        package = pkgs.flameshot.override {
          enableWlrSupport = true;
        };
        settings = {
          General = {
            contrastOpacity = 127;
            contrastUiColor = "#4476ff";
            copyPathAfterSave = true;
            disabledTrayIcon = true;
            drawColor = "#1e6cc5";
            drawThickness = 2;
            saveAfterCopy = true;
            # saveAfterCopyPath = "${config.home.homeDirectory}/Screenshots";
            savePath = "${config.home.homeDirectory}/Screenshots";
            savePathFixed = false;
            showHelp = false;
            showStartupLaunchMessage = true;
            startupLaunch = false;
            uiColor = "#003396";
            useGrimAdapter = true;
            disabledGrimWarning = true;
          };
        };
      };
      git-sync = {
        enable = true;
        repositories = {
          password-store = {
            path = config.programs.password-store.settings.PASSWORD_STORE_DIR;
            uri = "git+ssh://git@git.xandor.co.za:zeorin/password-store.git";
          };
        };
      };
      gpg-agent = {
        enable = true;
        enableSshSupport = true;
        enableExtraSocket = true;
        pinentry.package = pkgs.pinentry-gnome3;
        defaultCacheTtl = 0;
        maxCacheTtl = 0;
        defaultCacheTtlSsh = 0;
        maxCacheTtlSsh = 0;
      };
      kdeconnect = {
        enable = true;
        indicator = true;
      };
      mpris-proxy.enable = true;
      network-manager-applet.enable = true;
      nextcloud-client.enable = true;
      syncthing = {
        enable = true;
        tray = {
          enable = true;
          command = "syncthingtray --wait";
        };
      };
    };

    systemd.user = {
      services = {
        batsignal = {
          Unit.Description = "Battery monitor daemon";
          Service = {
            Type = "simple";
            ExecStart = "${pkgs.batsignal}/bin/batsignal -i";
            Restart = "on-failure";
            RestartSec = 1;
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
        languagetool =
          let
            settingsFormat = pkgs.formats.javaProperties { };
          in
          {
            Unit = {
              Description = "LanguageTool HTTP server";
              After = [ "network.target" ];
            };
            Install.WantedBy = [ "default.target" ];
            Service.ExecStart = ''
              ${pkgs.languagetool}/bin/languagetool-http-server \
                --port 8081 \
                --allow-origin '*' \
                --config ${
                  settingsFormat.generate "languagetool.cfg" {
                    cacheSize = "1000";
                    pipelineCaching = "true";
                    pipelinePrewarming = "true";
                    # https://dev.languagetool.org/finding-errors-using-n-gram-data
                    languageModel = "${pkgs.linkFarm "languagetool-languageModel" [
                      {
                        name = "en";
                        path = pkgs.fetchzip {
                          url = "https://languagetool.org/download/ngram-data/ngrams-en-20150817.zip";
                          hash = "sha256-v3Ym6CBJftQCY5FuY6s5ziFvHKAyYD3fTHr99i6N8sE=";
                        };
                      }
                      {
                        name = "nl";
                        path = pkgs.fetchzip {
                          url = "https://languagetool.org/download/ngram-data/ngrams-nl-20181229.zip";
                          hash = "sha256-bHOEdb2R7UYvXjqL7MT4yy3++hNMVwnG7TJvvd3Feg8=";
                        };
                      }
                    ]}";
                    fasttextBinary = pkgs.fetchurl {
                      url = "https://dl.fbaipublicfiles.com/fasttext/supervised-models/lid.176.bin";
                      hash = "sha256-fmnsVFG8JhzHhE5J5HkqhdfwnAZ4nsgA/EpErsNidk4=";
                    };
                  }
                }
            '';
          };
        tmux = {
          Unit.Description = "tmux server";
          Install.WantedBy = [ "default.target" ];
          Service = {
            ExecStart = "${config.programs.tmux.package}/bin/tmux -D";
            ExecStop = "${config.programs.tmux.package}/bin/tmux kill-server";
            Restart = "on-failure";
          };
        };
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
            Restart = "on-failure";
          };
        };
        yubikey-touch-detector = {
          Unit = {
            Description = "A tool to detect when your YubiKey is waiting for a touch";
            After = [ "graphical-session-pre.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          Install.WantedBy = [ "graphical-session.target" ];
          Service = {
            ExecStart = "${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector --libnotify";
            Restart = "on-abort";
          };
        };
      };
    };

    xdg = {
      enable = true;
      userDirs.enable = true;
      portal.xdgOpenUsePortal = true;
      configFile = with config.xdg; {
        "curl/.curlrc".text = ''
          write-out "\n"
          silent
          dump-header /dev/stderr
        '';
        "kitty/themes/Nord light.conf".text = ''
          # From: https://github.com/ayamir/nord-and-light/blob/master/.config/kitty/polar.conf
          foreground            #2E3440
          background            #D8DEE9
          selection_foreground  #FFFACD
          selection_background  #000000
          url_color             #81A1C1
          cursor                #0087BD

          # black
          color0   #3B4252
          color8   #4C566A

          # red
          color1   #BF616A
          color9   #BF616A

          # green
          color2   #A3BE8C
          color10  #A3BE8C

          # yellow
          color3   #EBCB8B
          color11  #EBCB8B

          # blue
          color4  #81A1C1
          color12 #81A1C1

          # magenta
          color5   #B48EAD
          color13  #B48EAD

          # cyan
          color6   #88C0D0
          color14  #8FBCBB

          # white
          color7   #E5E9F0
          color15  #ECEFF4
        '';
        "npm/npmrc".text = ''
          init-author-name=Xandor Schiefer
          init-author-email=me@xandor.co.za
          init-version=0.0.0
          init-license=LGPL-3.0
          prefix=${dataHome}/npm
          cache=${cacheHome}/npm
        '';
        "pipewire/pipewire.conf.d/10-source-rnnoise.conf" = {
          text = ''
            context.modules = [
            {   name = libpipewire-module-filter-chain
                args = {
                    node.description = "Noise Cancelling Source"
                    media.name = "Noise Cancelling Source"
                    filter.graph = {
                        nodes = [
                            {
                                type = ladspa
                                name = rnnoise
                                plugin = ${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so
                                label = noise_suppressor_mono
                                control = {
                                    "VAD Threshold (%)" = 50.0
                                    "VAD Grace Period (ms)" = 200
                                    "Retroactive VAD Grace (ms)" = 0
                                }
                            }
                        ]
                    }
                    capture.props = {
                        node.name =  "effect_input.rnnoise"
                        node.passive = true
                        target.object = "alsa_input.usb-0c76_USB_PnP_Audio_Device-00.mono-fallback"
                        audio.rate = 48000
                    }
                    playback.props = {
                        node.name =  "effect_output.rnnoise"
                        media.class = Audio/Source
                        audio.rate = 48000
                    }
                }
            }
            ]
          '';
          onChange = "${pkgs.writeShellScript "restart pipewire.service" ''
            ${pkgs.systemd}/bin/systemctl --user restart pipewire.service
          ''}";
        };
        "pipewire/pipewire.conf.d/20-echo-cancellation.conf" = {
          text = ''
            context.module = [
            {   name = libpipewire-module-echo-cancel
                args = {
                    library.name  = aec/libspa-aec-webrtc
                    aec.args = {
                        webrtc.extended_filter = true
                        webrtc.delay_agnostic = true
                        webrtc.high_pass_filter = true
                        webrtc.noise_suppression = false
                        webrtc.voice_detection = false
                        webrtc.gain_control = false
                        webrtc.experimental_agc = false
                        webrtc.experimental_ns = false
                    }
                    node.latency = 1024/48000
                    # monitor.mode = false
                    # https://docs.pipewire.org/page_module_echo_cancel.html:
                    #
                    # .--------.     .---------.     .--------.     .----------.     .-------.
                    # | source | --> | capture | --> |        | --> |  source  | --> |  app  |
                    # '--------'     '---------'     | echo   |     '----------'     '-------'
                    #                                | cancel |
                    # .--------.     .---------.     |        |     .----------.     .--------.
                    # |  app   | --> |  sink   | --> |        | --> | playback | --> |  sink  |
                    # '--------'     '---------'     '--------'     '----------'     '--------'
                    #
                    capture.props = {
                        # Cancel this sound out, should be un-cancelled mic input
                        node.description = "Echo Cancel Capture"
                        node.name = "echo_cancel.mic.input"
                        target.object = "effect_input.rnnoise"
                    }
                    sink.props = {
                        # Cancel sound out of this, should be set to system's default output so all apps' output will be cancelled
                        node.description = "Echo Cancel Sink"
                        node.name = "echo_cancel.playback.input"
                    }
                    source.props = {
                        # Echo-cancelled mic input, should be set to system's default input so all apps' mic input will be cancelled
                        node.description = "Echo Cancel Source"
                        node.name = "echo_cancel.mic.output"
                    }
                    playback.props = {
                        # Echo-cancelled sound output, this should be a hardware speaker, if left unassigned it intelligently chooses one
                        node.description = "Echo Cancel Playback"
                        node.name = "echo_cancel.playback.output"
                    }
                }
            }
            ]
          '';
          onChange = "${pkgs.writeShellScript "restart-pipewire.service" ''
            ${pkgs.systemd}/bin/systemctl --user restart pipewire.service
          ''}";
        };
        "pipewire/pipewire-pulse.conf.d/40-upmix.conf" = {
          text = ''
            stream.properties = {
                channelmix.upmix      = true
                channelmix.upmix-method = psd
                channelmix.lfe-cutoff = 150
                channelmix.fc-cutoff  = 12000
                channelmix.rear-delay = 12.0
            }
          '';
          onChange = "${pkgs.writeShellScript "restart-pipewire-pulse.service" ''
            ${pkgs.systemd}/bin/systemctl --user restart pipewire-pulse.service
          ''}";
        };
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
          bind ,g js let uri = document.location.href.replace(/https?:\/\//,"git@").replace("/",":").replace(/$/,".git"); tri.native.run("cd ~/projects; ${pkgs.git}/bin/git clone " + uri + "; cd \"$(${pkgs.coreutils}/bin/basename \"" + uri + "\" .git)\"; ${pkgs.unstable.app2unit}/bin/app2unit-term")

          " Handy multiwindow/multitasking binds
          bind gd tabdetach
          bind gD composite tabduplicate | tabdetach
          bind T composite tabduplicate

          " Better search bindings
          bind s fillcmdline tabopen search
          bind S fillcmdline open search

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

          " Fix clobbering of Tridactyl command line iframe
          " https://github.com/tridactyl/tridactyl/issues/4807
          autocmd DocStart .* js -s ${pkgs.writeText "restore-tridactyl-commandline.js" ''
            const cmdlineIframe = document.getElementById("cmdline_iframe");

            let { parentElement } = cmdlineIframe;

            const mutationObserver = new MutationObserver((records, mutationObserver) => {
              if (!parentElement.isConnected) {
                mutationObserver.disconnect();
                parentElement = document.documentElement;
                mutationObserver.observe(parentElement, { childList: true });
              }

              if (
                records.some(({ removedNodes }) =>
                  Array.from(removedNodes).includes(cmdlineIframe),
                )
              ) {

                parentElement.appendChild(cmdlineIframe);
              }
            });

            mutationObserver.observe(parentElement, { childList: true });
          ''}

          " Disable Tridactyl on certain websites
          ${lib.strings.concatMapStrings (url: "blacklistadd ${url}") [
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
            pkgs.base16-tridactyl
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
        "uwsm/env".source = "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";
        "wireplumber/bluetooth.lua.d/51-bluez-config.lua".text = ''
          bluez_monitor.properties = {
            ["bluez5.enable-sbc-xq"] = true,
            ["bluez5.enable-msbc"] = true,
            ["bluez5.enable-hw-volume"] = true,
            ["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
          }
        '';
        "wget/wgetrc".text = ''
          hsts-file = ${cacheHome}/wget-hsts
        '';
        "X11/xcompose".text = ''
          include "%L"

          <Multi_key> <apostrophe> <apostrophe>	: "ʹ"	U02B9 # MODIFIER LETTER PRIME
        '';
        "xkb".source = "${pkgs.big-bag-kbd-trix-xkb}/share/X11/xkb";
      };
      dataFile = {
        # TODO: This should be a systemd service that periodically checks for
        # updates to the files on disk and downloads new ones if there are.
        docsets.source = pkgs.linkFarm "docsets" (
          # https://kapeli.com/dash#docsets
          lib.mapAttrs
            (
              name: hash:
              pkgs.fetchzip {
                url = "https://kapeli.com/feeds/${name}.tgz";
                inherit hash;
                stripRoot = false;
              }
            )
            {
              CSS = "sha256-mi04jBXYXyKbS5SN1DBlogPJsyiwZaSjySJDq6fWERY=";
              Docker = "sha256-X8CwEDxabU2gpyAtng4ij++8LaJBvMEQDhZSVSA/q20=";
              Emacs_Lisp = "sha256-sTXNYv64F5whATuha6StMoBJRYtZau1WQYTWEu2Nd2I=";
              Emmet = "sha256-bTn7dJJ4fc+e4OzaWj4z0eeAZ7+wlutM3c2JTKU34QU=";
              Express = "sha256-E7+35AHVEG/wLyqRr7W+xbmdt0+n3VGm4wp57REPuhM=";
              ExtJS = "sha256-l8drgOXanSk1V8p5eoUCt8WInyIGfFH3XQE7AOYCcYs=";
              Font_Awesome = "sha256-5ERZC5oUtYRGVS7/Z7T72Nyvf6ZG3u0iqlPYjp04PsU=";
              HTML = "sha256-Cc0Ms59nY7+yFRZSt+6D8xQpaFukj4NVzjL8Lv0VuIE=";
              JavaScript = "sha256-U/sAcmLmlfyXMBEAQ33uLagl0myBtyMWr8tcAAHtXZ4=";
              Lo-Dash = "sha256-irVO2nDTbqlLVBaqkTR5MfxHyuoDQda3dfXs64bcqS8=";
              Markdown = "sha256-WRjWe1frF9Ys68a1jVJPqZkzEWQNr5OGaHnWbBijRGc=";
              MySQL = "sha256-BrmCvM019s5tJjcmGNMG/JayJJAyQ74s1fJb6M3y53g=";
              Nginx = "sha256-f/PHK6/35ts3EePaPqr+a4Zrvq8lCazo5PRIaAQwj54=";
              NodeJS = "sha256-7bTSwazAHctx4psUtUgKI8J23ptbm51dsfvSiv2gN1g=";
              PostgreSQL = "sha256-xN/OmUtK5SrRM6M0+GbHRLMb3S0kjHgTnXywwJHzeTs=";
              Python_3 = "sha256-rRu6tYTalHwv4ita5CzjSCrpHu150OyNGFj5wNUpXOQ=";
              React = "sha256-oGSms/Bi07bee19Lq8f/+2cAfb0/0D+c1YKErGZe4wM";
            }
        );
      };
    };

    home.file = {
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
      ".my.cnf".text = ''
        [mysql]
        no-beep
        [client]
        user = root
        password
        sigint-ignore
        auto-vertical-output
        i-am-a-dummy
        auto-rehash
        pager = "${pkgs.ccze}/bin/ccze -A | ${pkgs.less}/bin/less -RSFXin"
        prompt="\n[\d] "
      '';
      "${config.xdg.configHome}/starship.toml" =
        let
          tomlFormat = pkgs.formats.toml { };
          cfg = config.programs.starship;
          settings = tomlFormat.generate "starship-config" (cfg.settings);
          nerdFonts = pkgs.runCommandLocal "nerd-font-symbols.toml" { } ''
            echo -e "\n" > $out
            ${cfg.package}/bin/starship preset nerd-font-symbols >> $out
          '';
        in
        lib.mkIf cfg.enable {
          source = lib.mkForce (
            pkgs.concatTextFile {
              name = "starship.toml";
              files = (lib.optionals (cfg.settings != null) [ settings ]) ++ [ nerdFonts ];
            }
          );
        };
    };

    xresources = {
      path = "${config.xdg.configHome}/X11/xresources";
      properties =
        with lib.attrsets;
        {
          # fontconfig
          "Xft.autohint" = 0;
          "Xft.lcdfilter" = "lcddefault";
          "Xft.hintstyle" = "hintslight";
          "Xft.hinting" = 1;
          "Xft.antialias" = 1;
          "Xft.rgba" = "rgb";
        }
        # xterm
        // (mapAttrs' (name: value: nameValuePair "XTerm.${name}" value) (
          {
            termName = "xterm-256color";
            buffered = true;
            bufferedFPS = 60;
            ttyModes = "erase ^?";
          }
          // (mapAttrs' (name: value: nameValuePair "vt100.${name}" value) {
            backarrowKey = false;
            locale = false;
            utf8 = true;
            internalBorder = 11;
            visualbell = true;
            bellIsUrgent = true;
            fullscreen = "never";
            metaSendsEscape = true;
            alternateScroll = true;
            scrollTtyOutput = false;
            boldColors = false;
            faceName = "Iosevka NFM Light";
            faceSize = 10;
            faceSize1 = 6;
            faceSize2 = 8;
            faceSize3 = 10;
            faceSize4 = 14;
            faceSize5 = 18;
            translations = ''
              #override \
                Ctrl <Key> minus: smaller-vt-font() \n\
                Ctrl <Key> plus: larger-vt-font() \n\
                Ctrl <Key> 0: set-vt-font(d) \n\
                Shift <KeyPress> Insert: insert-selection(CLIPBOARD) \n\
                Ctrl Shift <Key>V:    insert-selection(CLIPBOARD) \n\
                Ctrl Shift <Key>C:    copy-selection(CLIPBOARD) \n\
                Ctrl <Btn1Up>: exec-formatted("${pkgs.unstable.app2unit}/bin/app2unit-open '%t'", PRIMARY)
            '';
          })
        ));
      extraConfig = ''
        #include "${
          pkgs.fetchFromGitHub {
            owner = "nordtheme";
            repo = "xresources";
            rev = "2e4d108bcf044d28469e098979bf6294329813fc";
            hash = "sha256-+f3ROQ2/2mh8wmMx0aGP1V0ZZTJH4sr0zyGGO/yLKss=";
          }
        }/src/nord"
      '';
    };

    fonts.fontconfig = {
      enable = true;
      defaultFonts = {
        emoji = [ "Twitter Color Emoji" ];
      };
    };

    dconf.settings = {
      "desktop/ibus/general" = {
        embed-preedit-text = true;
        use-global-engine = true;
        use-system-keyboard-layout = true;
        switcher-delay-time = -1;
      };
      "desktop/ibus/panel" = {
        show = 0;
        show-icon-on-systray = true;
      };
      "desktop/ibus/panel/emoji" = {
        hotkey = [
          "<Control><Shift>e"
          "XF86EmojiPicker"
        ];
        unicode-hotkey = [ "<Control><Shift>u" ];
      };
    };

    home.packages =
      with pkgs;
      [
        moreutils
        usbutils
        pciutils
        inetutils
        brightnessctl
        asciinema
        (symlinkJoin {
          name = "xdg-autostart-entries";
          paths =
            let
              makeAutostartItem = args: makeDesktopItem (args // { destination = "/etc/xdg/autostart"; });
            in
            builtins.map makeAutostartItem (
              [
                {
                  name = "tailscale-systray";
                  desktopName = "Tailscale SysTray";
                  exec = "${tailscale-systray}/bin/tailscale-systray";
                }
              ]
              ++ lib.optionals (osConfig.i18n.inputMethod.enable && osConfig.i18n.inputMethod.type == "ibus") [
                {
                  name = "ibus-daemon";
                  desktopName = "Ibus";
                  type = "Application";
                  exec = "ibus start --type wayland";
                  notShowIn = [
                    # GNOME will launch ibus using systemd
                    "GNOME"
                  ];
                }
              ]
            );
        })
        unstable.xdg-terminal-exec
        unstable.app2unit
        wev
        wl-clipboard
        wayland-utils
        xwayland-satellite
        (writeShellScriptBin "edit" ''
          exec $EDITOR "$@"
        '')
        (aspellWithDicts (
          dicts: with dicts; [
            en
            en-computers
            en-science
          ]
        ))
        (hunspell.withDicts (dicts: with dicts; [ en_GB-ise ]))
        (nuspell.withDicts (dicts: with dicts; [ en_GB-ise ]))
        enchant
        languagetool
        webcamoid
        kdePackages.kdenlive
        blender
        libnotify
        file
        tree
        curl
        httpie
        devenv
        xdg-user-dirs
        wineWowPackages.stableFull
        winetricks
        protontricks
        protonup-ng
        wget
        wireshark
        websocat
        vim
        qtpass
        open-in-editor
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
        tailscale-systray
        protonvpn-gui
        thunderbird
        neomutt
        zathura
        sigil
        calibre
        # (pkgs.nur.repos.milahu.kindle_1_17_0.override { wine = wineWowPackages.stableFull; })
        gnome-calculator
        file-roller
        yt-dlp
        screenkey
        slop
        system-config-printer
        gnucash
        xournalpp
        transmission_4-gtk
        newpipelist
        weechat
        yubikey-manager
        yubioath-flutter
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
        # onlyoffice-desktopeditors
        pdfchain
        hledger
        fava
        arandr
        ethtool
        pavucontrol
        ncdu
        qutebrowser
        luakit
        (qmk.overrideAttrs (oldAttrs: {
          propagatedBuildInputs =
            oldAttrs.propagatedBuildInputs
            ++ (with python3Packages; [
              pyserial
              pillow
            ]);
        }))
        dfu-programmer
        vial
        peek
      ]
      ++ (
        let
          firefox = config.programs.firefox.package.override (oldArgs: {
            cfg = { };
            # Generated by https://ffprofile.com/
            extraPolicies = (oldArgs.extraPolicies or { }) // {
              CaptivePortal = false;
              DisableFirefoxStudies = true;
              DisableTelemetry = true;
              OverrideFirstRunPage = "";
              OverridePostUpdatePage = "";
              UserMessaging = {
                WhatsNew = false;
                ExtensionRecommendations = false;
                FeatureRecommendations = false;
                SkipOnboarding = true;
                MoreFromMozilla = false;
              };
            };
            # Generated by https://ffprofile.com/
            extraPrefs = (oldArgs.extraPrefs or "") + ''
              pref("app.normandy.api_url", "");
              pref("app.normandy.enabled", false);
              pref("app.normandy.migrationsApplied", 12);
              pref("app.shield.optoutstudies.enabled", false);
              pref("app.update.auto", false);
              pref("breakpad.reportURL", "");
              pref("browser.aboutConfig.showWarning", false);
              pref("browser.aboutwelcome.enabled", false);
              pref("browser.crashReports.unsubmittedCheck.autoSubmit", false);
              pref("browser.crashReports.unsubmittedCheck.autoSubmit2", false);
              pref("browser.crashReports.unsubmittedCheck.enabled", false);
              pref("browser.disableResetPrompt", true);
              pref("browser.newtabpage.enhanced", false);
              pref("browser.newtabpage.introShown", true);
              pref("browser.selfsupport.url", "");
              pref("browser.sessionstore.privacy_level", 0);
              pref("browser.shell.checkDefaultBrowser", false);
              pref("browser.startup.homepage_override.mstone", "ignore");
              pref("browser.tabs.inTitlebar", 0);
              pref("browser.tabs.crashReporting.sendReport", false);
              pref("browser.toolbarbuttons.introduced.pocket-button", true);
              pref("browser.toolbars.bookmarks.visibility", "never");
              pref("browser.urlbar.trimURLs", false);
              pref("datareporting.healthreport.service.enabled", false);
              pref("datareporting.healthreport.uploadEnabled", false);
              pref("datareporting.policy.dataSubmissionEnabled", false);
              pref("doh-rollout.doneFirstRun", true);
              pref("experiments.activeExperiment", false);
              pref("experiments.enabled", false);
              pref("experiments.manifest.uri", "");
              pref("experiments.supported", false);
              pref("extensions.getAddons.cache.enabled", false);
              pref("extensions.getAddons.showPane", false);
              pref("extensions.shield-recipe-client.api_url", "");
              pref("extensions.shield-recipe-client.enabled", false);
              pref("extensions.webservice.discoverURL", "");
              pref("media.autoplay.default", 0);
              pref("media.autoplay.enabled", true);
              pref("network.allow-experiments", false);
              pref("network.captive-portal-service.enabled", false);
              pref("network.cookie.cookieBehavior", 1);
              pref("network.http.referer.XOriginPolicy", 2);
              pref("privacy.donottrackheader.enabled", true);
              pref("privacy.donottrackheader.value", 1);
              pref("privacy.trackingprotection.cryptomining.enabled", true);
              pref("privacy.trackingprotection.enabled", true);
              pref("privacy.trackingprotection.fingerprinting.enabled", true);
              pref("privacy.trackingprotection.pbmode.enabled", true);
              pref("services.sync.prefs.sync.browser.newtabpage.activity-stream.showSponsoredTopSite", false);
              pref("startup.homepage_override_url", "");
              pref("startup.homepage_welcome_url", "");
              pref("startup.homepage_welcome_url.additional", "");
              pref("toolkit.telemetry.archive.enabled", false);
              pref("toolkit.telemetry.bhrPing.enabled", false);
              pref("toolkit.telemetry.cachedClientID", "");
              pref("toolkit.telemetry.enabled", false);
              pref("toolkit.telemetry.firstShutdownPing.enabled", false);
              pref("toolkit.telemetry.hybridContent.enabled", false);
              pref("toolkit.telemetry.newProfilePing.enabled", false);
              pref("toolkit.telemetry.prompted", 2);
              pref("toolkit.telemetry.rejected", true);
              pref("toolkit.telemetry.reportingpolicy.firstRun", false);
              pref("toolkit.telemetry.server", "");
              pref("toolkit.telemetry.shutdownPingSender.enabled", false);
              pref("toolkit.telemetry.unified", false);
              pref("toolkit.telemetry.unifiedIsOptIn", false);
              pref("toolkit.telemetry.updatePing.enabled", false);
              pref("trailhead.firstrun.didSeeAboutWelcome", true);
              pref("trailhead.firstrun.branches", "nofirstrun-empty");
            '';
          });
          firefox-guest = pkgs.writeShellScriptBin "firefox-guest" ''
            profile="$(mktemp --directory -t firefox-guest.XXXXXXXXXX)"
            nonce="''${profile##*.}"
            wm_class="firefox-guest.$nonce"

            "${firefox}/bin/firefox" \
              --profile "$profile" \
              --name "$wm_class" \
              --wait-for-browser \
              "$@"

            rm -rf "$profile"
          '';
        in
        [
          firefox-guest
          (firefox.desktopItem.override (oldArgs: {
            name = "firefox-guest";
            desktopName = "${oldArgs.desktopName} Guest Session";
            exec = "${firefox-guest}/bin/firefox-guest %U";
          }))
        ]
      )
      ++ (
        let
          wrapFirefoxWithProfile =
            { name, profile, ... }@args:
            pkg:
            let
              inherit (pkg.passthru.unwrapped) binaryName;
            in
            pkgs.runCommandLocal "${binaryName}-with-${profile}-profile"
              (
                {
                  buildInputs = with pkgs; [
                    makeWrapper
                    xorg.lndir
                  ];
                }
                // (removeAttrs args [
                  "name"
                  "profile"
                ])
              )
              ''
                # Symlink everything
                mkdir -p "$out"
                lndir -silent "${pkg}" "$out"

                # Remove symlink to original wrapper, if it exists, this may
                # collide with the same file in other firefox packages.
                # Workaround for issue fixed by
                # https://github.com/NixOS/nixpkgs/pull/294971
                rm -f "$out/bin/.${binaryName}-wrapper"

                # remove links to colliding files
                rm -f "$out"/lib/firefox/browser/features/*.xpi

                # Make our wrapper
                rm "$out/bin/${name}"
                makeWrapper "${pkg}/bin/${name}" "$out/bin/${name}" \
                  --add-flags '-P "${profile}"' \
                  ''${makeWrapperArgs}
              '';
        in
        [
          (wrapFirefoxWithProfile
            {
              name = "firefox-devedition";
              profile = "developer-edition";
            }
            (
              unstable.firefox-devedition.override {
                nativeMessagingHosts = with pkgs; [
                  browserpass
                  tridactyl-native
                ];
              }
            )
          )
          (wrapFirefoxWithProfile
            {
              name = "firefox-beta";
              profile = "beta";
            }
            (
              firefox-beta.override {
                nativeMessagingHosts = with pkgs; [
                  browserpass
                  tridactyl-native
                ];
              }
            )
          )
          (wrapFirefoxWithProfile
            {
              name = "firefox-esr";
              profile = "esr";
            }
            (
              firefox-esr.override {
                nativeMessagingHosts = with pkgs; [
                  browserpass
                  tridactyl-native
                ];
              }
            )
          )
        ]
      )
      ++ [
        ungoogled-chromium
        google-chrome
        netflix
        tor-browser
        virt-manager
        virt-viewer
        qemu_full
        quickemu
        slack
        zulip
        wasistlos
        discord
        telegram-desktop
        signal-desktop
        zoom-us
        element-desktop
        ferdium
        unstable.spotify
        # https://github.com/NixOS/nixpkgs/issues/179323
        prismlauncher
        modorganizer2-linux-installer
        manix
        cachix
        nix-prefetch-git
        nix-prefetch
        nix-update
        expect
        nh
        nix-output-monitor
        keybase
        zeal
        dasht

        # For dark mode toggling
        xfce.xfconf

        (retroarch.withCores (
          cores:
          lib.filter (
            core:
            (core ? libretroCore) && (lib.meta.availableOn stdenv.hostPlatform core) && (!core.meta.unfree)
          ) (lib.attrValues cores)
        ))

        mangohud

      ]
      ++ [

        #########
        # FONTS #
        #########

        et-book
        geist-font

        # Emoji
        # emojione
        twitter-color-emoji
        # twemoji-color-font
        # noto-fonts-emoji
        # noto-fonts-emoji-blob-bin
        # joypixels

        # Classic fonts
        eb-garamond
        # helvetica-neue-lt-std
        libre-bodoni
        libre-caslon
        libre-franklin
        etBook

        # Microsoft fonts
        corefonts
        vista-fonts

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
        (
          (google-fonts.overrideAttrs (oldAttrs: {
            nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ perl ];
            installPhase = (oldAttrs.installPhase or "") + ''
              skip=("NotoColorEmoji")

              readarray -t fonts < <(find . -name '*.ttf' -exec basename '{}' \; | perl -pe 's/(.+?)[[.-].*/\1/g' | sort | uniq)

              for font in "''${fonts[@]}"; do
                [[ "_''${skip[*]}_" =~ _''${font}_ ]] && continue
                find . -name "''${font}*.ttf" -exec install -m 444 -Dt $dest '{}' +
              done
            '';
          })).override
          {
            # Don't install fonts in the original `installPhase`
            fonts = [ "__NO_FONT__" ];
          }
        )

        # The League of Movable Type
        the-neue-black
        blackout
        chunk
        # fanwood
        # goudy-bookletter-1911
        junction-font
        knewave
        # league-gothic
        # league-script-number-one
        # league-spartan
        # linden-hill
        # orbitron
        ostrich-sans
        # prociono
        # raleway
        # sniglet
        # sorts-mill-goudy

        # Iosevka and friends
        iosevka
        (iosevka-bin.override { variant = "Aile"; })
        (iosevka-bin.override { variant = "Etoile"; })

        # Other Coding fonts
        # hack-font
        # go-font
        # hasklig
        # fira-code
        # inconsolata
        # mononoki
        # fantasque-sans-mono

        # Nerd Fonts
        nerd-fonts.iosevka
        # Set FontConfig to use the symbols only font as a fallback for most
        # monospaced fonts, this gives us the symbols even for fonts that we
        # didn't install Nerd Fonts versions of. The Symbols may not be perfectly
        # suited to that font (the patched fonts usually have adjustments to the
        # Symbols specifically for that font), but it's better than nothing.
        nerd-fonts.symbols-only
        (stdenv.mkDerivation (finalAttrs: {
          inherit (nerd-fonts.symbols-only) version;
          pname = "nerdfonts-fontconfig";
          src = fetchurl {
            url = "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/v${finalAttrs.version}/10-nerd-font-symbols.conf";
            hash = "sha256-g7cLf3BqztHc7V0K7Gfgtu96f+6fyzcTVxfrdoeGjNM=";
          };
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
        }))

        # Apple Fonts
      ]
      ++ (
        let
          mkAppleFont =
            { name, src }:
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
        in
        [
          (mkAppleFont {
            name = "san-francisco-pro";
            src = pkgs.fetchurl {
              url = "https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg";
              hash = "sha256-Lk14U5iLc03BrzO5IdjUwORADqwxKSSg6rS3OlH9aa4=";
            };
          })
          (mkAppleFont {
            name = "san-francisco-compact";
            src = pkgs.fetchurl {
              url = "https://devimages-cdn.apple.com/design/resources/download/SF-Compact.dmg";
              hash = "sha256-CMNP+sL5nshwK0lGBERp+S3YinscCGTi1LVZVl+PuOM=";
            };
          })
          (mkAppleFont {
            name = "san-francisco-mono";
            src = pkgs.fetchurl {
              url = "https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg";
              hash = "sha256-bUoLeOOqzQb5E/ZCzq0cfbSvNO1IhW1xcaLgtV2aeUU=";
            };
          })
          (mkAppleFont {
            name = "new-york";
            src = pkgs.fetchurl {
              url = "https://devimages-cdn.apple.com/design/resources/download/NY.dmg";
              hash = "sha256-HC7ttFJswPMm+Lfql49aQzdWR2osjFYHJTdgjtuI+PQ=";
            };
          })
        ]
      )
      ++ [

        # Non-latin character sets
        junicode

        # Fallback fonts
        cm_unicode
        xorg.fontcursormisc
        symbola
        freefont_ttf
        unifont
        noto-fonts
        noto-fonts-cjk-sans

      ];

    # Nicely reload system units when changing configs
    systemd.user.startServices = "sd-switch";

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    home.stateVersion = "25.11";
  };
}
