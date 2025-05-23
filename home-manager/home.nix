# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)

{
  lib,
  config,
  pkgs,
  inputs,
  outputs,
  ...
}@moduleArgs:

let
  round = x: if ((x / 2.0) >= 0.5) then (builtins.ceil x) else (builtins.floor x);

  dpiScale = x: round (x * (config.dpi / 96.0));

  myKey = "0x5E1C0971FE4F665A";

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
      sessionChooserFish = pkgs.writeScript "tmux-session-chooser.fish" ''
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
    };
    setDesktopBackground = pkgs.writeShellScript "set-desktop-background" ''
      color_scheme="$(${pkgs.darkman}/bin/darkman get)"

      if [ -f "${config.xdg.dataHome}/picom/env" ]; then
        source "${config.xdg.dataHome}/picom/env"
      fi

      if [ "$PICOM_SHADER" = "grayscale" ]; then
        color_scheme="''${color_scheme}-gray"
      fi

      if [ "$color_scheme" = "light" ]; then
        background_image="${./backgrounds/martian-terrain-light.jpg}"
      elif [ "$color_scheme" = "light-gray" ]; then
        background_image="${./backgrounds/martian-terrain-light-gray.jpg}"
      elif [ "$color_scheme" = "dark" ]; then
        background_image="${./backgrounds/martian-terrain-dark.jpg}"
      elif [ "$color_scheme" = "dark-gray" ]; then
        background_image="${./backgrounds/martian-terrain-dark-gray.jpg}"
      fi

      ${pkgs.feh}/bin/feh --no-fehbg --no-xinerama --bg-fill "$background_image"
    '';
  };
  terminal-emulator = "${config.programs.kitty.package}/bin/kitty";

  collectPathArgs = ''
    paths=()
    while [ "$#" -gt 0 ]; do
      arg="$1"
      [[ "$arg" =~ ^--?.+ ]] && break
      paths+=("$arg"); shift
    done
  '';
  pathArgs = ''"''${paths[@]}"'';
  collectFlakeFlags = ''
    flakeFlags=()
    while [ "$#" -gt 0 ]; do
      arg="$1"
      case "$arg" in
        ${
          builtins.concatStringsSep "|" [
            "build"
            "bundle"
            "copy"
            "daemon"
            "derivation"
            "develop"
            "doctor"
            "edit"
            "eval"
            "flake"
            "fmt"
            "hash"
            "help"
            "help-stores"
            "key"
            "log"
            "nar"
            "path-info"
            "print-dev-env"
            "profile"
            "realisation"
            "registry"
            "repl"
            "run"
            "search"
            "shell"
            "show-config"
            "store"
            "upgrade-nix"
            "why-depends"
          ]
        })
          break
          ;;
        *)
          flakeFlags+=("$arg"); shift
          ;;
      esac
    done
  '';
  flakeFlags = ''"''${flakeFlags[@]}"'';
  nixNomArgs = "--log-format internal-json --verbose";
  nixBuildCmdWithNomArgs = buildCmd: ''
    ${collectPathArgs}
    ${buildCmd} ${pathArgs} ${nixNomArgs} "$@"
  '';
  nixShellCmdWithNomArgs = shellCmd: ''
    ${shellCmd} ${nixNomArgs} "$@"
  '';
  nixStoreCmdWithNomArgs = storeCmd: ''
    operation="$1"; shift
    case "$operation" in
      --realise|-r)
        ${collectPathArgs}
        ${storeCmd} "$operation" ${pathArgs} ${nixNomArgs} "$@"
        ;;
      *)
        ${storeCmd} "$operation" "$@"
        ;;
    esac
  '';
  nixWithNomArgs =
    nix:
    pkgs.symlinkJoin {
      name = "nix-with-nom-args-${nix.version}";
      paths =
        (lib.attrsets.mapAttrsToList pkgs.writeShellScriptBin {
          nix = ''
            program="$(basename $0)"
            case "$program" in
              nix)
                ${collectFlakeFlags}
                command="$1"; shift
                case "$command" in
                  build)
                    ${nixBuildCmdWithNomArgs "${nix}/bin/nix ${flakeFlags} build"}
                    ;;
                  shell)
                    ${nixShellCmdWithNomArgs "${nix}/bin/nix ${flakeFlags} shell"}
                    ;;
                  store)
                    ${nixStoreCmdWithNomArgs "${nix}/bin/nix ${flakeFlags} store"}
                    ;;
                  *)
                    ${nix}/bin/nix ${flakeFlags} "$command" "$@"
                    ;;
                esac
                ;;
              *)
                "${nix}/bin/$program" "$@"
                ;;
            esac
          '';
          nix-build = nixBuildCmdWithNomArgs "${nix}/bin/nix-build";
          nix-shell = nixShellCmdWithNomArgs "${nix}/bin/nix-shell";
          nix-store = nixStoreCmdWithNomArgs "${nix}/bin/nix-store";
        })
        ++ [ nix ];
    };
  nixNomPkgs =
    {
      nix ? null,
      nixos-rebuild ? null,
      home-manager ? null,
    }:
    lib.attrsets.mapAttrs pkgs.writeShellScriptBin (
      (
        if nix != null then
          {
            nix = ''
              program="$(basename $0)"
              case "$program" in
                nix)
                  ${collectFlakeFlags}
                  command="$1"; shift
                  case "$command" in
                    build|shell|develop)
                      ${pkgs.nix-output-monitor}/bin/nom ${flakeFlags} "$command" "$@"
                      ;;
                    *)
                      ${nix}/bin/nix ${flakeFlags} "$command" "$@"
                      ;;
                  esac
                  ;;
                *)
                  "${nix}/bin/$program" "$@"
                  ;;
              esac
            '';
            nix-build = ''
              ${pkgs.nix-output-monitor}/bin/nom-build "$@"
            '';
            nix-shell = ''
              ${pkgs.nix-output-monitor}/bin/nom-shell "$@"
            '';
            nix-store = ''
              ${nixWithNomArgs nix}/bin/nix-store "$@" \
                |& ${pkgs.nix-output-monitor}/bin/nom --json
            '';
          }
        else
          { }
      )
      // (
        if nixos-rebuild != null then
          {
            nixos-rebuild = ''
              ${pkgs.expect}/bin/unbuffer \
                ${
                  nixos-rebuild.override (old: {
                    nix = nixWithNomArgs old.nix;
                  })
                }/bin/nixos-rebuild "$@" \
                |& ${pkgs.nix-output-monitor}/bin/nom --json
            '';
          }
        else
          { }
      )
      // (
        if home-manager != null then
          {
            home-manager = ''
              PATH="${nixWithNomArgs pkgs.nix}/bin:$PATH" \
                ${pkgs.expect}/bin/unbuffer \
                ${home-manager}/bin/home-manager "$@" \
                |& ${pkgs.nix-output-monitor}/bin/nom --json
            '';
          }
        else
          { }
      )
    );
  nomAliases = pkgs: lib.attrsets.mapAttrs (name: pkg: "${pkg}/bin/${name}") (nixNomPkgs pkgs);
  wrapWithNom =
    let
      inherit (pkgs) symlinkJoin;
    in
    (
      pkgs:
      symlinkJoin {
        name = "wrapped-with-nom";
        paths = (builtins.attrValues (nixNomPkgs pkgs)) ++ (builtins.attrValues pkgs);
      }
    );

in
{
  # You can import other home-manager modules here
  imports = [
    inputs.nur.modules.homeManager.default
    inputs.nix-index-database.hmModules.nix-index
    inputs.nixos-vscode-server.homeModules.default
    ./emacs
  ];

  options = with lib; {
    dpi = mkOption {
      type = with types; int;
      default = moduleArgs.osConfig.dpi or 96;
      example = 192;
    };

    nixpkgs.allowUnfreePackages = mkOption {
      type = with types; (listOf (either str (functionTo bool)));
      default = [ ];
    };
  };

  config = {
    nixpkgs = lib.mkIf (!(moduleArgs.osConfig.home-manager.useGlobalPkgs or false)) {
      # You can add overlays here
      overlays = [
        # Add overlays your own flake exports (from overlays and pkgs dir):
        outputs.overlays.additions
        outputs.overlays.modifications
        outputs.overlays.unstable-packages

        (final: prev: {
          fcitx5-with-addons = prev.fcitx5-with-addons.overrideAttrs (oldAttrs: {
            postBuild = ''
              ${oldAttrs.postBuild or ""}
              # Don't install bundled phrases
              rm $out/share/fcitx5/data/quickphrase.d/*.mb
              # Don't install desktop files
              desktop=share/applications/org.fcitx.Fcitx5.desktop
              autostart=etc/xdg/autostart/org.fcitx.Fcitx5.desktop
              rm $out/$autostart
              mv $out/$desktop $out/$autostart
              rm -rf $out/share/applications
            '';
          });
        })
      ];

      # Configure your nixpkgs instance
      config = {
        joypixels.acceptLicense = true;
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
        "steam" # protontricks
        "steam-run" # protontricks
        "steam-unwrapped" # protontricks
        (pkg: lib.hasPrefix "libretro-" (lib.getName pkg)) # retroarchFull
        "corefonts"
        "vista-fonts"
        "joypixels"
        "xkcd-font"
        "san-francisco-pro"
        "san-francisco-compact"
        "san-francisco-mono"
        "new-york"
        "symbola"
        "spotify"
        "google-chrome"
        "netflix-via-google-chrome"
        "netflix-icon"
        "enhancer-for-youtube"
        "slack"
        "discord"
        "zoom"
        "code"
        "vscode"
        "vscode-extension-ms-vscode-remote-remote-ssh"
        "cudatoolkit"
        "cudatoolkit-11-cudnn"
        "cudatoolkit-11.8-tensorrt"
        "aspell-dict-en-science"
      ];
    };

    home = {
      username = "zeorin";
      homeDirectory = "/home/${config.home.username}";
      keyboard = {
        layout = "us,us";
        variant = "dvp,";
        options = [
          "grp:alt_space_toggle"
          "grp_led:scroll"
          "compose:menu"
          "terminate:ctrl_alt_bksp"
        ];
      };
      sessionVariables = with config.xdg; {
        LESS = "-FRXix2$";
        # Non-standard env var, found in https://github.com/i3/i3/blob/next/i3-sensible-terminal
        TERMINAL = "${terminal-emulator}";
        BATDIFF_USE_DELTA = "true";
        DELTA_FEATURES = "+side-by-side";

        EDITOR_URL = "editor://{path}:{line}";
        # Non-standard env var, found in https://github.com/yyx990803/launch-editor
        LAUNCH_EDITOR = pkgs.writeShellScript "launch-editor" ''
          file="$1"
          line="$2"
          column="$3"
          command="${pkgs.xdg-utils}/bin/xdg-open \"editor://$file\""
          [ -n "$line" ] && command="$command:$line"
          [ -n "$column" ] && command="$command:$column"
          eval $command
        '';
        OPEN_IN_EDITOR = config.home.sessionVariables.VISUAL or config.home.sessionVariables.EDITOR;

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
          for dir in bash go pass stack wineprefixes picom; do
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
      shellAliases =
        # (nomAliases { inherit (pkgs) nix nixos-rebuild home-manager; }) // {
        {
          g = "git";
          e = "edit";
          m = "neomutt";
          o = "xdg-open";
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
          eval "$(batpipe)"
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
            plasma-browser-integration
            tridactyl-native
          ];
        };
        profiles =
          let
            extensions =
              with pkgs.nur.repos.rycee.firefox-addons;
              [
                a11ycss
                amp2html
                auto-tab-discard
                browserpass
                canvasblocker
                clearurls
                cookies-txt
                darkreader
                enhancer-for-youtube
                fediact
                ghosttext
                mailvelope
                metamask
                octolinker
                octotree
                org-capture
                plasma-integration
                privacy-badger
                react-devtools
                reddit-enhancement-suite
                reduxdevtools
                refined-github
                sponsorblock
                tab-session-manager
                terms-of-service-didnt-read
                tree-style-tab
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
              inherit extensions;
            };
            developer-edition = {
              id = 1;
              settings = commonSettings // noNoiseSuppression;
              inherit extensions;
            };
            beta = {
              id = 2;
              settings = commonSettings // noNoiseSuppression;
              inherit extensions;
            };
            esr = {
              id = 3;
              settings = commonSettings // noNoiseSuppression;
              inherit extensions;
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
        userName = "Xandor Schiefer";
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
        };
        signing = {
          key = myKey;
          signByDefault = true;
        };
        delta = {
          enable = true;
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
        aliases =
          {
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
          } Noto Color Emoji
        '';
      };
      less = {
        enable = true;
        keys = ''
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
          (uosc.overrideAttrs (
            finalAttrs: oldAttrs: {
              version = "5.5.0";
              src = pkgs.fetchFromGitHub {
                owner = "tomasklaen";
                repo = "uosc";
                rev = finalAttrs.version;
                hash = "sha256-WFsqA5kGefQmvihLUuQBfMmKoUHiO7ofxpwISRygRm4=";
              };
            }
          ))
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
        plugins = with pkgs.obs-studio-plugins; [ obs-backgroundremoval ];
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
          PASSWORD_STORE_GPG_OPTS = "--no-throw-keyids";
          PASSWORD_STORE_GENERATED_LENGTH = "128";
          PASSWORD_STORE_CHARACTER_SET = "[:print:]"; # All printable characters
        };
      };
      rofi = {
        enable = true;
        pass = {
          enable = true;
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
                  ${pkgs.rofi}/bin/rofi \
                    -dpi ${toString config.dpi} \
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
              y-offset = mkLiteral "${toString (dpiScale 280)}px";
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
        # By default add the key to the agent so we're not asked for the passphrase again
        addKeysToAgent = "yes";
        # Enable compression for slow networks, for fast ones this slows it down
        # compression = true;
        # Share connections to same host
        controlMaster = "auto";
        controlPath = "\${XDG_RUNTIME_DIR}/master-%r@%n:%p";
        controlPersist = "5m";
        extraConfig = ''
          # Only attempt explicitly specified identities
          IdentitiesOnly yes
          IdentityFile ~/.ssh/id_ed25519

          # Use a faster cipher
          Ciphers aes128-gcm@openssh.com,aes256-gcm@openssh.com,chacha20-poly1305@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr

          # Login more quickly by bypassing IPv6 lookup
          AddressFamily inet

          # Update GPG's startup tty for every ssh command
          Match host * exec "${config.programs.gpg.package}/bin/gpg-connect-agent updatestartuptty /bye"
        '';
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
        clock24 = true;
        keyMode = "vi";
        mouse = true;
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

          set-option -g update-environment 'DISPLAY SSH_ASKPASS SSH_AUTH_SOCK SSH_AGENT_PID SSH_CONNECTION WINDOWID XAUTHORITY TERM'

          # Don't try to interpret Escape key sequences
          set-option -sg escape-time 0
        '';

        plugins = with pkgs.tmuxPlugins; [
          pain-control
          nord
          {
            plugin = better-mouse-mode;
            extraConfig = ''
              set-option -g @scroll-without-changing-pane 'on'
              set-option -g @emulate-scroll-for-no-mouse-alternate-buffer 'on'
            '';
          }
          {
            plugin = mkTmuxPlugin {
              pluginName = "transient-status";
              version = "unstable-2024-07-07";
              rtpFilePath = "main.tmux";
              src = pkgs.fetchFromGitHub {
                owner = "TheSast";
                repo = "tmux-transient-status";
                rev = "c3fcd5180999a7afc075d2dd37d37d1b1b82f7e8";
                sha256 = "sha256-fOIn8hVVBDFVLwzmPZP+Bf3ccxy/hsAnKIXYD9yv3BE=";
              };
            };
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
      urxvt = {
        enable = true;
        fonts = [ "xft:Iosevka NFM Light:size=11" ];
        keybindings = {
          "Shift-Control-C" = "eval:selection_to_clipboard";
          "Shift-Control-V" = "eval:paste_clipboard";
        };
        scroll.bar.enable = false;
        extraConfig = {
          internalBorder = 11;
          scrollWithBuffer = true;
          secondaryScreen = 1;
          secondaryScroll = 0;
          letterSpace = -1;
          iso14755 = false;
          iso14755_52 = false;
        };
      };
      vscode = with pkgs; {
        enable = true;
        package = vscode-fhs;
        extensions =
          (with vscode-extensions; [
            bbenoist.nix
            vscodevim.vim
            ms-vscode-remote.remote-ssh
          ])
          ++ vscode-utils.extensionsFromVscodeMarketplace [
            {
              name = "direnv";
              publisher = "mkhl";
              version = "0.6.1";
              sha256 = "sha256-5/Tqpn/7byl+z2ATflgKV1+rhdqj+XMEZNbGwDmGwLQ=";
            }
            {
              name = "remote-containers";
              publisher = "ms-vscode-remote";
              version = "0.247.0";
              sha256 = "sha256-gWFNjkx2+zjkpKDC5a1qIZ5SbcDN8ahtXDPX1upWUg8=";
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
        darkModeScripts = {
          notify = ''
            ${pkgs.libnotify}/bin/notify-send --app-name="darkman" --urgency=low --icon=weather-clear-night "Switching to dark mode"
          '';
          gtk-theme = ''
            ${pkgs.xfce.xfconf}/bin/xfconf-query --create --type string --channel xsettings --property /Net/ThemeName --set "${
              builtins.replaceStrings [ "Light" ] [ "Dark" ] config.gtk.theme.name
            }"
            ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/gtk-theme "'${
              builtins.replaceStrings [ "Light" ] [ "Dark" ] config.gtk.theme.name
            }'"
            ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
            ${pkgs.dconf}/bin/dconf write /org/freedesktop/appearance/color-scheme "'prefer-dark'"
          '';
          kvantum-theme = ''
            ${pkgs.kdePackages.qtstyleplugin-kvantum}/bin/kvantummanager --set ColloidNordDark
          '';
          icon-theme = ''
            ${pkgs.xfce.xfconf}/bin/xfconf-query --create --type string --channel xsettings --property /Net/IconThemeName --set "${
              builtins.replaceStrings [ "light" ] [ "dark" ] config.gtk.iconTheme.name
            }"
            ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/icon-theme "'${
              builtins.replaceStrings [ "light" ] [ "dark" ] config.gtk.iconTheme.name
            }'"
          '';
          cursor-theme = ''
            ${pkgs.xfce.xfconf}/bin/xfconf-query --create --type string --channel xsettings --property /Gtk/CursorThemeName --set "${
              builtins.replaceStrings [ "light" ] [ "dark" ] config.gtk.cursorTheme.name
            }"
            ${pkgs.xfce.xfconf}/bin/xfconf-query --create --type int --channel xsettings --property /Gtk/CursorThemeSize --set ${toString config.gtk.cursorTheme.size}
            ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/cursor-theme "'${
              builtins.replaceStrings [ "light" ] [ "dark" ] config.gtk.cursorTheme.name
            }'"
            ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/cursor-size ${toString config.gtk.cursorTheme.size}
            ${pkgs.xorg.xsetroot}/bin/xsetroot -xcf "${config.gtk.cursorTheme.package}/share/icons/${
              builtins.replaceStrings [ "light" ] [ "dark" ] config.gtk.cursorTheme.name
            }/cursors/left_ptr" ${toString config.gtk.cursorTheme.size}
          '';
          inherit (scripts) setDesktopBackground;
        };
        lightModeScripts = {
          notify = ''
            ${pkgs.libnotify}/bin/notify-send --app-name="darkman" --urgency=low --icon=weather-clear "Switching to light mode"
          '';
          gtk-theme = ''
            ${pkgs.xfce.xfconf}/bin/xfconf-query --create --type string --channel xsettings --property /Net/ThemeName --set "${config.gtk.theme.name}"
            ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/gtk-theme "'${config.gtk.theme.name}'"
            ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'prefer-light'"
            ${pkgs.dconf}/bin/dconf write /org/freedesktop/appearance/color-scheme "'prefer-light'"
          '';
          kvantum-theme = ''
            ${pkgs.kdePackages.qtstyleplugin-kvantum}/bin/kvantummanager --set ColloidNord
          '';
          icon-theme = ''
            ${pkgs.xfce.xfconf}/bin/xfconf-query --create --type string --channel xsettings --property /Net/IconThemeName --set "${config.gtk.iconTheme.name}"
            ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/icon-theme "'${config.gtk.iconTheme.name}'"
          '';
          cursor-theme = ''
            ${pkgs.xfce.xfconf}/bin/xfconf-query --create --type string --channel xsettings --property /Gtk/CursorThemeName --set "${config.gtk.cursorTheme.name}"
            ${pkgs.xfce.xfconf}/bin/xfconf-query --create --type int --channel xsettings --property /Gtk/CursorThemeSize --set ${toString config.gtk.cursorTheme.size}
            ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/cursor-theme "'${config.gtk.cursorTheme.name}'"
            ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/cursor-size ${toString config.gtk.cursorTheme.size}
            ${pkgs.xorg.xsetroot}/bin/xsetroot -xcf "${config.gtk.cursorTheme.package}/share/icons/${config.gtk.cursorTheme.name}/cursors/left_ptr" ${toString config.gtk.cursorTheme.size}
          '';
          inherit (scripts) setDesktopBackground;
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
            dmenu = "${pkgs.rofi}/bin/rofi -dpi ${toString config.dpi} -dmenu -p dunst";
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
      flameshot.enable = true;
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
        pinentryPackage = pkgs.pinentry-gnome3;
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
      picom = {
        enable = true;
        package =
          let
            picomPkg = pkgs.picom-next;
          in
          pkgs.symlinkJoin {
            name = "picom";
            paths = [
              (pkgs.writeShellScriptBin "picom" (
                let
                  grayscale-glsl = pkgs.writeText "grayscale.glsl" ''
                    #version 330

                    in vec2 texcoord;
                    uniform sampler2D tex;
                    uniform float opacity;

                    vec4 default_post_processing(vec4 c);

                    vec4 window_shader() {
                      vec2 texsize = textureSize(tex, 0);
                      vec4 color = texture2D(tex, texcoord / texsize, 0);

                      color = vec4(vec3(0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b) * opacity, color.a * opacity);

                      return default_post_processing(color);
                    }
                  '';
                in
                ''
                  if [ "$PICOM_SHADER" = "grayscale" ]; then
                    "${picomPkg}/bin/picom" \
                      --window-shader-fg="${grayscale-glsl}" \
                      "$@"
                  else
                    "${picomPkg}/bin/picom" "$@"
                  fi
                ''
              ))
              pkgs.picom
            ];
          }
          // {
            inherit (pkgs.picom) meta;
          };
        backend = "glx";
        fade = true;
        fadeDelta = 3;
        inactiveOpacity = 0.95;
        menuOpacity = 0.95;
        shadow = true;
        shadowOffsets = [
          (-7)
          (-7)
        ];
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
          "(class_g *?= 'firefox' || class_g = 'thunderbird') && (window_type = 'utility' || window_type = 'popup_menu') && argb"
          # notifications
          "_NET_WM_WINDOW_TYPE@:32a *= '_NET_WM_WINDOW_TYPE_NOTIFICATION'"
          # Zoom
          "name = 'cpt_frame_xcb_window'"
          "class_g *?= 'zoom' && name *?= 'meeting'"
        ];
        opacityRules =
          # Only apply these opacity rules if the windows are not hidden
          map (str: str + " && !(_NET_WM_STATE@[*]:a *= '_NET_WM_STATE_HIDDEN')") [
            "100:class_g *?= 'zoom' && name *?= 'meeting'"
            "100:role = 'browser' && name ^= 'Meet -'"
            "100:role = 'browser' && name ^= 'Netflix'"
          ]
          ++ [ "0:_NET_WM_STATE@[*]:a *= '_NET_WM_STATE_HIDDEN'" ];
        vSync = true;
        settings = {
          inactive-dim = 0.2;
          blur = {
            method = "dual_kawase";
            strength = 5;
          };
          corner-radius = dpiScale 8;
          rounded-corners-exclude = [
            "window_type = 'dock'"
            "window_type = 'desktop'"
          ];
          blur-background-exclude = [
            # shaped windows
            "bounding_shaped && !rounded_corners"
            # hidden windows
            "_NET_WM_STATE@[*]:a *= '_NET_WM_STATE_HIDDEN'"
            # stacked / tabbed windows
            "_NET_WM_STATE@[0]:a = '_NET_WM_STATE@_MAXIMIZED_VERT'"
            "_NET_WM_STATE@[0]:a = '_NET_WM_STATE@_MAXIMIZED_HORZ'"
            # i3 borders
            "class_g = 'i3-frame'"
            # GTK
            "_GTK_FRAME_EXTENTS@:c"
            "class_g ~= 'xdg-desktop-portal' && _NET_FRAME_EXTENTS@:c && window_type = 'dialog'"
            "class_g ~= 'xdg-desktop-portal' && window_type = 'menu'"
            "_NET_FRAME_EXTENTS@:c && WM_WINDOW_ROLE@:s = 'Popup'"
            # Mozilla fixes
            "(class_g *?= 'firefox' || class_g = 'thunderbird') && (window_type = 'utility' || window_type = 'popup_menu') && argb"
            # Zoom
            "name = 'cpt_frame_xcb_window'"
            "class_g *?= 'zoom' && name *?= 'meeting'"
            "class_g = 'Peek'"
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
          win-types = {
            tooltip = {
              fade = true;
              shadow = true;
              opacity = 0.8;
              focus = true;
              full-shadow = false;
            };
            dock = {
              shadow = false;
              clip-shadow-above = true;
            };
            dnd = {
              shadow = false;
            };
            popup_menu = {
              opacity = 0.9;
            };
            dropdown_menu = {
              opacity = 0.9;
            };
          };
        };
      };
      polybar = {
        enable = true;
        package = pkgs.polybar.override {
          i3Support = true;
          mpdSupport = true;
        };
        settings =
          let
            superColors = colors;
          in
          let
            colors = superColors // {
              background = colors.nord0;
              foreground = colors.nord9;
              foreground-alt = colors.nord10;
              urgent = colors.nord12;
              alert = colors.nord13;
            };
            mkFormats =
              let
                formats = [
                  "format"
                  # "format-volume"
                  # "format-muted"
                  # "format-mounted"
                  # "format-unmounted"
                  # "format-connected"
                  # "format-disconnected"
                  # "format-charging"
                  # "format-discharging"
                  # "format-full"
                  # "format-low"
                ];
              in
              attrset:
              lib.lists.foldr (
                format: acc:
                acc
                // (lib.attrsets.mapAttrs' (name: value: {
                  inherit value;
                  name = "${format}-${name}";
                }) attrset)
              ) { } formats;
            mkAlpha = str: "#cc${lib.strings.removePrefix "#" str}";
          in
          {
            settings = {
              screenchange-reload = true;
              # https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-operator-t
              compositing-background = "source";
              compositing-foreground = "source";
              compositing-overline = "over";
              compositing-underline = "over";
              compositing-border = "over";
              pseudo-transparency = false;
            };
            "bar/top" = {
              inherit (colors) foreground;
              background = "${mkAlpha colors.background}";
              monitor = "\${env:MONITOR:}";
              monitor-strict = true;
              monitor-exact = true;
              inherit (config) dpi;
              width = "100%";
              height = "${toString (dpiScale 24)}px";
              enable-struts = true;
              double-click-interval = 150;
              override-redirect = false;
              wm-restack = "i3";

              fixed-center = true;

              # For symbols
              font-0 = "Symbols Nerd Font Mono:size=10;2";
              # For Powerline glyphs
              font-1 = "Symbols Nerd Font Mono:size=18;3";
              # If it's not a symbol, it falls back to this
              font-2 = "Iosevka:size=8;2";

              format-foreground = colors.foreground;
              format-background = "${mkAlpha colors.background}";

              modules-left = "i3 title";
              # modules-center = "yubikey mpd";
              modules-center = "yubikey";
              modules-right = "audio-input audio-output xkeyboard battery date";
            };
            "bar/top-primary" = {
              "inherit" = "bar/top";
              modules-right = "audio-input audio-output xkeyboard battery date tray";
            };
            "powerline/right-facing-arrow" = {
              type = "custom/text";
              label = "";
              label-font = 2;
              label-foreground = "\${self.background}";
              label-background = "\${self.background-next}";
            };
            "powerline/right-facing-separator" = {
              type = "custom/text";
              label = "";
              label-font = 2;
              label-foreground = "\${self.separator}";
              label-background = "\${self.background}";
            };
            "powerline/left-facing-arrow" = {
              type = "custom/text";
              label = "";
              label-font = 2;
              label-foreground = "\${self.background}";
              label-background = "\${self.background-next}";
            };
            "powerline/left-facing-separator" = {
              type = "custom/text";
              label = "";
              label-font = 2;
              label-foreground = "\${self.separator}";
              label-background = "\${self.background}";
            };
            "powerline/left-section-arrow" = mkFormats {
              suffix = "\${powerline/right-facing-arrow.label}";
              suffix-font = "\${powerline/right-facing-arrow.label-font}";
              suffix-foreground = "\${self.background}";
              suffix-background = "\${self.background-next}";
            };
            "powerline/left-section-separator" = mkFormats {
              prefix = "\${powerline/right-facing-separator.label}";
              prefix-font = "\${powerline/right-facing-separator.label-font}";
              prefix-foreground = "\${self.separator}";
              prefix-background = "\${self.background}";
            };
            "powerline/right-section-arrow" = mkFormats {
              prefix = "\${powerline/left-facing-arrow.label}";
              prefix-font = "\${powerline/left-facing-arrow.label-font}";
              prefix-foreground = "\${self.background}";
              prefix-background = "\${self.background-next}";
            };
            "powerline/right-section-separator" = mkFormats {
              suffix = "\${powerline/left-facing-separator.label}";
              suffix-font = "\${powerline/left-facing-separator.label-font}";
              suffix-foreground = "\${self.separator}";
              suffix-background = "\${self.background}";
            };
            "module/i3" = {
              "inherit" = "powerline/left-section-arrow";
              type = "internal/i3";
              strip-wsnumbers = true;
              pin-workspaces = true;
              show-urgent = true;
              index-sort = true;
              enable-scroll = false;
              wrapping-scroll = false;

              format = "<label-mode> <label-state> ";
              format-foreground = colors.nord0;
              format-background = "${mkAlpha colors.nord3}";
              format-prefix = "  ";
              format-prefix-background = "${mkAlpha colors.nord3}";
              background = "${mkAlpha colors.nord3}";
              background-next = "${mkAlpha colors.nord1}";

              label-mode-foreground = colors.alert;
              label-mode-padding = 1;

              label-separator = "​"; # zero-width space
              label-separator-padding = 1;

              # unfocused = Inactive workspace on any monitor
              label-unfocused = "%name%";

              # focused = Active workspace on focused monitor
              label-focused = "%name%";
              label-focused-foreground = colors.nord6;

              # visible = Active workspace on unfocused monitor
              label-visible = "%name%";

              # urgent = Workspace with urgency hint set
              label-urgent = "%name%";
              label-urgent-foreground = colors.urgent;
            };
            "module/title" = {
              "inherit" = "powerline/left-section-arrow";
              type = "internal/xwindow";
              format-foreground = colors.nord4;
              format-background = "${mkAlpha colors.nord1}";
              background = "${mkAlpha colors.nord1}";
              background-next = "${mkAlpha colors.nord0}";
              # Prepend a zero-width space to keep rendering
              # the suffix even on an empty workspace
              label = " %title:0:120:…% ";
              label-empty = " ";
            };
            "module/mpd" = {
              type = "internal/mpd";
              format-online = "<label-song> <bar-progress> <label-time>  <icon-prev> <icon-seekb> <icon-stop> <toggle> <icon-seekf> <icon-next>  <icon-repeat> <icon-random>";
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
              label-song-foreground = colors.nord4;

              label-time-foreground = colors.nord4;

              bar-progress-width = 30;
              bar-progress-indicator = "|";
              bar-progress-indicator-foreground = colors.nord2;
              bar-progress-fill = "─";
              bar-progress-fill-foreground = colors.nord4;
              bar-progress-empty = "─";
              bar-progress-empty-foreground = colors.nord3;
            };
            "module/yubikey" =
              let
                indicator-script = pkgs.writeShellScript "yubikey-indicator" ''
                  ${pkgs.nmap}/bin/ncat --unixsock $XDG_RUNTIME_DIR/yubikey-touch-detector.socket | while read -n5 message; do
                    [[ $message = *1 ]] && echo "                " || echo ""
                  done
                '';
              in
              {
                type = "custom/script";
                exec = indicator-script;
                tail = true;
                format-background = colors.urgent;
                format-foreground = "${mkAlpha colors.background}";
                format-prefix = "\${powerline/left-facing-arrow.label}";
                format-prefix-font = "\${powerline/left-facing-arrow.label-font}";
                format-prefix-foreground = colors.urgent;
                format-prefix-background = "${mkAlpha colors.background}";
                format-suffix = "\${powerline/right-facing-arrow.label}";
                format-suffix-font = "\${powerline/right-facing-arrow.label-font}";
                format-suffix-foreground = colors.urgent;
                format-suffix-background = "${mkAlpha colors.background}";
              };
            "module/audio-input" = {
              "inherit" = "powerline/right-section-separator";
              format-foreground = colors.nord4;
              format-background = "${mkAlpha colors.nord1}";
              format-prefix = "\${powerline/left-facing-arrow.label}";
              format-prefix-font = "\${powerline/left-facing-arrow.label-font}";
              format-prefix-foreground = "${mkAlpha colors.nord1}";
              format-prefix-background = "${mkAlpha colors.nord0}";
              background = "${mkAlpha colors.nord1}";
              separator = "${mkAlpha colors.nord0}";
              type = "custom/script";
              tail = true;
              exec = ''${pkgs.polybar-pulseaudio-control}/bin/pulseaudio-control --node-type input --icons-volume "󰍬" --icon-muted "󰍭" --color-muted ${lib.strings.removePrefix "#" colors.nord0} --node-blacklist "*.monitor" --notifications listen'';
              click-right = "exec ${pkgs.pavucontrol}/bin/pavucontrol &";
              click-left = "${pkgs.polybar-pulseaudio-control}/bin/pulseaudio-control --node-type input togmute";
              click-middle = "${pkgs.polybar-pulseaudio-control}/bin/pulseaudio-control --node-type input next-node";
              scroll-up = "${pkgs.polybar-pulseaudio-control}/bin/pulseaudio-control --node-type input --volume-max 130 up";
              scroll-down = "${pkgs.polybar-pulseaudio-control}/bin/pulseaudio-control --node-type input --volume-max 130 down";
            };
            "module/audio-output" = {
              "inherit" = "powerline/right-section-separator";
              format-foreground = colors.nord4;
              format-background = "${mkAlpha colors.nord1}";
              background = "${mkAlpha colors.nord1}";
              separator = "${mkAlpha colors.nord0}";
              type = "custom/script";
              tail = true;
              exec = ''${pkgs.polybar-pulseaudio-control}/bin/pulseaudio-control --icons-volume "󰕿 ,󰖀 ,󰕾 " --icon-muted "󰖁 " --color-muted ${lib.strings.removePrefix "#" colors.nord0} --node-nicknames-from "device.description" --notifications listen'';
              click-right = "exec ${pkgs.pavucontrol}/bin/pavucontrol &";
              click-left = "${pkgs.polybar-pulseaudio-control}/bin/pulseaudio-control togmute";
              click-middle = "${pkgs.polybar-pulseaudio-control}/bin/pulseaudio-control next-node";
              scroll-up = "${pkgs.polybar-pulseaudio-control}/bin/pulseaudio-control --volume-max 130 up";
              scroll-down = "${pkgs.polybar-pulseaudio-control}/bin/pulseaudio-control --volume-max 130 down";
            };
            "module/xkeyboard" = {
              "inherit" = "powerline/right-section-separator";
              format-foreground = colors.nord4;
              format-background = "${mkAlpha colors.nord1}";
              background = "${mkAlpha colors.nord1}";
              separator = "${mkAlpha colors.nord0}";

              type = "internal/xkeyboard";

              label-layout = " 󰌓 %icon%";
              layout-icon-0 = "us;programmer Dvorak;DVP";
              layout-icon-1 = "us;US;US";

              indicator-icon-default = "";
              indicator-icon-0 = "caps lock;;󰌎";
              indicator-icon-1 = "scroll lock;;󱅜";
              indicator-icon-2 = "num lock;;󰎠";

              label-indicator-on = "%icon%";
              label-indicator-off = "";
            };
            "module/battery" = {
              "inherit" = "powerline/right-section-separator";
              format-foreground = colors.nord4;
              format-background = "${mkAlpha colors.nord1}";
              background = "${mkAlpha colors.nord1}";
              separator = "${mkAlpha colors.nord0}";

              type = "internal/battery";
              battery = "BAT0";
              adapter = "ADP1";

              format-charging = "<animation-charging> <label-charging>";
              format-charging-foreground = colors.nord4;
              format-charging-background = "${mkAlpha colors.nord1}";

              format-discharging = "<ramp-capacity> <label-discharging>";
              format-discharging-foreground = colors.nord4;
              format-discharging-background = "${mkAlpha colors.nord1}";

              format-full = "<ramp-capacity> <label-full>";
              format-full-foreground = colors.nord4;
              format-full-background = "${mkAlpha colors.nord1}";

              low-at = 15;
              format-low = "<animation-low> <label-low>";
              format-low-foreground = colors.urgent;
              format-low-background = "${mkAlpha colors.nord1}";

              ramp-capacity-0 = " ";
              ramp-capacity-1 = " ";
              ramp-capacity-2 = " ";
              ramp-capacity-3 = " ";
              ramp-capacity-4 = " ";

              animation-charging-0 = " ";
              animation-charging-1 = " ";
              animation-charging-2 = " ";
              animation-charging-3 = " ";
              animation-charging-4 = " ";
              animation-charging-framerate = 750;

              animation-low-0 = " ";
              animation-low-1 = " ";
              animation-low-framerate = 200;

            };
            "module/date" = {
              "inherit" = "powerline/right-section-separator";
              format = "󱑃 <label>";
              format-foreground = colors.nord4;
              format-background = "${mkAlpha colors.nord1}";
              format-prefix = " ";
              format-suffix = "";
              background = "${mkAlpha colors.nord1}";
              separator = "${mkAlpha colors.nord0}";

              type = "internal/date";
              interval = 1;

              date = "";
              date-alt = " %Y-%m-%d";

              time = "%H:%M";
              time-alt = "%H:%M:%S";

              label = "%time%%date%";
            };
            "module/tray" = {
              "inherit" = "powerline/right-section-arrow";
              background = "${mkAlpha colors.nord3}";
              background-next = "${mkAlpha colors.nord1}";
              format-foreground = colors.nord0;
              format-background = "${mkAlpha colors.nord3}";
              label-tray-padding = "8px";

              type = "internal/tray";

              tray-background = "${mkAlpha colors.nord3}";
              tray-foreground = colors.nord4;
              tray-padding = 2;
            };
          };
        script = ''
          ${pkgs.coreutils}/bin/sleep 1
          # Launch bar on each monitor, tray on primary
          ${pkgs.xorg.xrandr}/bin/xrandr --query | ${pkgs.gnugrep}/bin/grep " connected " | while IFS=$'\n' read line; do
            monitor=$(echo $line | ${pkgs.coreutils}/bin/cut -d' ' -f1)
            if [[ $line == *" primary "* ]]; then
              export MONITOR=$monitor tray_position="right"
              polybar top-primary &
            else
              export MONITOR=$monitor tray_position="none"
              polybar top &
            fi
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
        keybindings =
          let
            flameshot-region = (
              pkgs.writeShellScript "flameshot-region" ''
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
              ''
            );
          in
          {
            # Screenshot
            "Print" = "${pkgs.flameshot}/bin/flameshot gui";
            "super + Print" = "${flameshot-region} activewindow";
            "super + shift + Print" = "${flameshot-region}";
            "super + o" =
              "${pkgs.flameshot}/bin/flameshot gui --accept-on-select --raw | ${pkgs.imagemagick}/bin/convert -resize 400% png:- png:- | ${pkgs.tesseract}/bin/tesseract -l eng --psm 6 - - | ${pkgs.xsel}/bin/xsel -bi; ${pkgs.libnotify}/bin/notify-send --icon Clipboard --urgency low --expire-time 5000 'OCR result copied to clipboard'";

            # Notifications
            "super + dollar" = "${pkgs.dunst}/bin/dunstctl close";
            "super + shift + dollar" = "${pkgs.dunst}/bin/dunstctl close-all";
            "super + ampersand" = "${pkgs.dunst}/bin/dunstctl history-pop";
            "super + m" = "${pkgs.dunst}/bin/dunstctl action 0";
            "super + shift + m" = "${pkgs.dunst}/bin/dunstctl context";

            # Toggle grayscale
            "super + shift + g" = "${pkgs.writeShellScript "toggle-grayscale" ''
              if [ -f ${config.xdg.dataHome}/picom/env ]; then
                rm ${config.xdg.dataHome}/picom/env
                ${pkgs.libnotify}/bin/notify-send --app-name="picom" --urgency=low "Switching to colour mode"
              else
                ln -s ${config.xdg.configHome}/picom/env-grayscale ${config.xdg.dataHome}/picom/env
                ${pkgs.libnotify}/bin/notify-send --app-name="picom" --urgency=low "Switching to grayscale mode"
              fi
              ${scripts.setDesktopBackground}
              ${pkgs.systemd}/bin/systemctl --user restart picom.service
            ''}";

            # Toggle dark mode
            "super + shift + d" = "${pkgs.darkman}/bin/darkman toggle";

            # Transparency controls
            "super + Home" = "${pkgs.picom}/bin/picom-trans --current --delete";
            "super + button2" = "${pkgs.picom}/bin/picom-trans --current --delete";
            "super + Prior" = "${pkgs.picom}/bin/picom-trans --current --opacity=-5";
            "super + button5" = "${pkgs.picom}/bin/picom-trans --current --opacity=-5";
            "super + Next" = "${pkgs.picom}/bin/picom-trans --current --opacity=+5";
            "super + button4" = "${pkgs.picom}/bin/picom-trans --current --opacity=+5";
            "super + End" = "${pkgs.picom}/bin/picom-trans --current --opacity=100";
            "super + shift + button2" = "${pkgs.picom}/bin/picom-trans --current --opacity=100";

            # Lock screen
            "super + x" = "${pkgs.systemd}/bin/loginctl lock-session";

            # Programs
            "super + p" = "${pkgs.rofi-pass}/bin/rofi-pass";
            "super + shift + e" =
              "${config.programs.emacs.finalPackage}/bin/emacsclient –eval '(emacs-everywhere)'";

            # Audio controls
            "XF86AudioRaiseVolume" = "${pkgs.pulseaudio}/bin/pactl set-sink-volume 0 +5%";
            "XF86AudioLowerVolume" = "${pkgs.pulseaudio}/bin/pactl set-sink-volume 0 -5%";
            "XF86AudioMute" = "${pkgs.pulseaudio}/bin/pactl set-sink-mute 0 toggle";
            "XF86AudioPlay" = "${pkgs.playerctl}/bin/playerctl play-pause";
            "XF86AudioPause" = "${pkgs.playerctl}/bin/playerctl pause";
            "XF86AudioNext" = "${pkgs.playerctl}/bin/playerctl next";
            "XF86AudioPrev" = "${pkgs.playerctl}/bin/playerctl previous";
            "XF86AudioForward" = "${pkgs.playerctl}/bin/playerctl position 5+";
            "XF86AudioRewind" = "${pkgs.playerctl}/bin/playerctl position 5-";

            # Screen brightness controls
            "XF86MonBrightnessUp" = "${pkgs.brightnessctl}/bin/brightnessctl --device='*' --exponent=4 set 5%+";
            "XF86MonBrightnessDown" =
              "${pkgs.brightnessctl}/bin/brightnessctl --device='*' --exponent=4 set 5%-";
          };
      };
      syncthing = {
        enable = true;
        tray = {
          enable = true;
          command = "syncthingtray --wait";
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
      initExtra = ''
        ${scripts.setDesktopBackground} &
      '';
      windowManager.i3 = {
        enable = true;
        package = pkgs.i3-gaps;
        config =
          let
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
          in
          {
            bars = [ ];
            gaps = {
              inner = 10;
              outer = 5;
              smartGaps = true;
            };
            fonts = {
              names = [ "DejaVu Sans Mono" ];
              style = "Regular";
              size = 0.0;
            };
            modifier = "Mod4";
            terminal = terminal-emulator;
            menu = ''"${pkgs.rofi}/bin/rofi -dpi ${toString config.dpi} -show drun -run-shell-command '{terminal} -e \\" {cmd}; read -n 1 -s\\"'"'';
            focus = {
              followMouse = false;
              newWindow = "urgent";
              wrapping = "workspace";
            };
            startup = [
              {
                command = "${pkgs.writeShellScript "i3-session-start" ''
                  ${pkgs.systemd}/bin/systemctl --user set-environment I3SOCK=$(${config.xsession.windowManager.i3.package}/bin/i3 --get-socketpath)
                  ${pkgs.systemd}/bin/systemctl --user start graphical-session-i3.target
                ''}";
                notification = false;
              }
              {
                command =
                  let
                    i3-session-exit = pkgs.writeShellScript "i3-session-exit" ''
                      ${pkgs.systemd}/bin/systemctl --user stop graphical-session-i3.target
                    '';
                  in
                  "${pkgs.writeScript "i3-on-exit" ''
                    #!${pkgs.python3.withPackages (ps: with ps; [ i3ipc ])}/bin/python
                    from subprocess import Popen
                    from i3ipc.aio import Connection, Event

                    def on_exit(i3, e):
                        if e.change == "exit":
                          Popen(['${i3-session-exit}'])

                    i3 = await Connection().connect()

                    i3.on(Event.SHUTDOWN_EXIT, on_exit)

                    await i3.main()
                  ''}";
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
              let
                mod = config.xsession.windowManager.i3.config.modifier;
              in
              lib.mkOptionDefault {
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
                "${mod}+Shift+1" = "move container to workspace ${workspace1}; workspace ${workspace1}";
                "${mod}+Shift+2" = "move container to workspace ${workspace2}; workspace ${workspace2}";
                "${mod}+Shift+3" = "move container to workspace ${workspace3}; workspace ${workspace3}";
                "${mod}+Shift+4" = "move container to workspace ${workspace4}; workspace ${workspace4}";
                "${mod}+Shift+5" = "move container to workspace ${workspace5}; workspace ${workspace5}";
                "${mod}+Shift+6" = "move container to workspace ${workspace6}; workspace ${workspace6}";
                "${mod}+Shift+7" = "move container to workspace ${workspace7}; workspace ${workspace7}";
                "${mod}+Shift+8" = "move container to workspace ${workspace8}; workspace ${workspace8}";
                "${mod}+Shift+9" = "move container to workspace ${workspace9}; workspace ${workspace9}";
                "${mod}+Shift+0" = "move container to workspace ${workspace10}; workspace ${workspace10}";

                "${mod}+Shift+f" = "sticky toggle";

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
                "${mod}+Shift+at" = "move container to output left; focus output left";
                "${mod}+Shift+Ctrl+at" = "move workspace to output left";
                "${mod}+slash" = "focus output right";
                "${mod}+Shift+slash" = "move container to output right; focus output right";
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
                "o" = ''mode "${mode-gaps-outer}"'';
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
              "${workspace2}" = [
                {
                  class = "^firefox";
                  instance = "^Navigator$";
                }
              ];
              "${workspace9}" = [ { class = "^thunderbird$"; } ];
              "${workspace10}" = [
                { class = "^TelegramDesktop$"; }
                { class = "^Slack$"; }
                { class = "^Signal$"; }
                { class = "^Ferdium$"; }
              ];
            };
            floating.titlebar = false;
            window = {
              border = 0;
              hideEdgeBorders = "both";
              titlebar = false;
              commands =
                let
                  mkCommand = command: criteria: { inherit command criteria; };
                  mkFloating = mkCommand "floating enable";
                  mkSticky = mkCommand "sticky enable";
                in
                [
                  {
                    criteria = {
                      class = ".*";
                    };
                    command = "border pixel 0";
                  }
                  {
                    criteria = {
                      floating_from = "auto";
                      title = " is sharing your screen\.$";
                    };
                    command = "border none, sticky enable, move position 0 px -${toString (dpiScale 55)}px";
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
                  (mkFloating { class = "(?i)protonvpn"; })
                  (mkFloating { title = "Preferences$"; })
                  (mkFloating { window_role = "About"; })
                  (mkFloating { window_role = "Preferences"; })
                  (mkFloating { window_role = "Organizer"; })
                  (mkFloating { window_role = "bubble"; })
                  (mkFloating { window_role = "page-info"; })
                  (mkFloating { window_role = "pop-up"; })
                  (mkFloating { window_role = "task_dialog"; })
                  (mkFloating { window_role = "toolbox"; })
                  (mkFloating { window_role = "webconsole"; })
                  (mkFloating { window_type = "dialog"; })
                  (mkFloating { window_type = "menu"; })
                  (mkSticky { title = "Picture-in-Picture"; })
                  (mkSticky { title = "AlarmWindow"; })
                ];
            };
          };
        extraConfig = ''
          popup_during_fullscreen leave_fullscreen
        '';
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
        picom.Service.EnvironmentFile = "-${config.xdg.dataHome}/picom/env";
        polkit-authentication-agent = {
          Unit = {
            Description = "Polkit authentication agent";
            Documentation = "https://gitlab.freedesktop.org/polkit/polkit/";
            After = [ "graphical-session-pre.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          Install.WantedBy = [ "graphical-session.target" ];
          Service = {
            ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
            Restart = "on-failure";
          };
        };
        # https://github.com/nix-community/home-manager/issues/213#issuecomment-829743999
        polybar = {
          Unit.After = [ "graphical-session-i3.target" ];
          Install.WantedBy = lib.mkForce [ "graphical-session-i3.target" ];
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
      targets = {
        graphical-session-i3.Unit = {
          Description = "i3 X session";
          BindsTo = [ "graphical-session.target" ];
          Requisite = [ "graphical-session.target" ];
          Wants = [ "xdg-autostart.target" ];
        };
        xdg-autostart.Unit = {
          Description = "Run XDG autostart files";
          Requires = [
            "xdg-desktop-autostart.target"
            "graphical-session.target"
          ];
          Before = [
            "xdg-desktop-autostart.target"
            "graphical-session.target"
          ];
          BindsTo = [ "graphical-session.target" ];
        };
      };
    };

    xdg = {
      enable = true;
      userDirs.enable = true;
      configFile = with config.xdg; {
        "curl/.curlrc".text = ''
          write-out "\n"
          silent
          dump-header /dev/stderr
        '';
        "flameshot/flameshot.ini" = {
          text = ''
            [General]
            contrastOpacity=127
            contrastUiColor=#4476ff
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
        "fcitx5".source = pkgs.symlinkJoin {
          name = "config-fcitx5";
          paths = [
            (pkgs.writeTextDir "config" ''
              [Hotkey]
              TriggerKeys=
              EnumerateWithTriggerKeys=False
              AltTriggerKeys=
              EnumerateForwardKeys=
              EnumerateBackwardKeys=
              EnumerateSkipFirst=False
              EnumerateGroupForwardKeys=
              EnumerateGroupBackwardKeys=
              ActivateKeys=
              DeactivateKeys=
              [Hotkey/PrevPage]
              0=Up
              [Hotkey/NextPage]
              0=Down
              [Hotkey/PrevCandidate]
              0=Shift+Tab
              [Hotkey/NextCandidate]
              0=Tab
              [Hotkey/TogglePreedit]
              0=
              [Behavior]
              ActiveByDefault=False
              ShareInputState=No
              PreeditEnabledByDefault=False
              ShowInputMethodInformation=False
              showInputMethodInformationWhenFocusIn=False
              CompactInputMethodInformation=False
              ShowFirstInputMethodInformation=False
              DefaultPageSize=5
              OverrideXkbOption=False
              CustomXkbOption=
              EnabledAddons=
              PreloadInputMethod=True
              AllowInputMethodForPassword=False
              ShowPreeditForPassword=False
              [Behavior/DisabledAddons]
              0=clipboard
              1=emoji
              2=imselector
              3=kimpanel
              4=notificationitem
              5=notifications
              6=spell
            '')
            (pkgs.writeTextDir "profile" ''
              [Groups/0]
              Name=Default
              Default Layout=us-dvp
              DefaultIM=keyboard-us
              [Groups/0/Items/0]
              Name=keyboard-us-dvp
              Layout=
              [Groups/0/Items/1]
              Name=keyboard-us
              Layout=
              [GroupOrder]
              0=Default
            '')
            (pkgs.writeTextDir "conf/classicui.conf" ''
              Vertical Candidate List=True
              WheelForPaging=True
              PreferTextIcon=False
              ShowLayoutNameInIcon=False
              UseInputMethodLanguageToDisplayText=False
              Theme=Nord-Light
              DarkTheme=Nord-Dark
              UseDarkTheme=True
              UseAccentColor=True
              PerScreenDPI=False
              ForceWaylandDPI=${toString config.dpi}
              EnableFractionalScale=True
            '')
            (pkgs.writeTextDir "conf/keyboard.conf" ''
              PageSize=5
              EnableEmoji=False
              EnableQuickPhraseEmoji=True
              Choose Modifier=None
              EnableHintByDefault=False
              Hint Trigger=
              One Time Hint Trigger=
              UseNewComposeBehavior=True
              EnableLongPress=False
              [PrevCandidate]
              0=Shift+Tab
              [NextCandidate]
              0=Tab
            '')
            (pkgs.writeTextDir "conf/quickphrase.conf" ''
              Choose Modifier=None
              Spell=False
              FallbackSpellLanguage=en
              [TriggerKey]
              0=Super+period
            '')
            (pkgs.writeTextDir "conf/unicode.conf" ''
              [TriggerKey]
              0=Control+Alt+Shift+U
              [DirectUnicodeMode]
              0=Control+Shift+U
            '')
            (pkgs.writeTextDir "conf/xcb.conf" ''
              Allow Overriding System XKB Settings=False
              AlwaysSetToGroupLayout=False
            '')
          ];
        };
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
        "Kvantum/ColloidNord".source = "${
          pkgs.colloid-kde.overrideAttrs (oldAttrs: {
            postInstall =
              (oldAttrs.postInstall or "")
              + ''
                rm -r $out/share/Kvantum/ColloidNord/ColloidNordDark.*
              '';
          })
        }/share/Kvantum/ColloidNord";
        "Kvantum/ColloidNordDark".source = "${
          pkgs.colloid-kde.overrideAttrs (oldAttrs: {
            postInstall =
              (oldAttrs.postInstall or "")
              + ''
                rm -r $out/share/Kvantum/ColloidNord/ColloidNord.*
              '';
          })
        }/share/Kvantum/ColloidNord";
        "npm/npmrc".text = ''
          init-author-name=Xandor Schiefer
          init-author-email=me@xandor.co.za
          init-version=0.0.0
          init-license=LGPL-3.0
          prefix=${dataHome}/npm
          cache=${cacheHome}/npm
        '';
        "picom/env-grayscale".text = ''
          PICOM_SHADER="grayscale"
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
        "starship.toml" =
          let
            tomlFormat = pkgs.formats.toml { };
            cfg = config.programs.starship;
            settings = tomlFormat.generate "starship-config" (cfg.settings);
            nerdFonts = pkgs.runCommandLocal "nerd-font-symbols.toml" { } ''
              ${cfg.package}/bin/starship preset nerd-font-symbols -o $out
            '';
          in
          lib.mkForce (
            lib.mkIf cfg.enable {
              source = lib.mkMerge [
                (lib.mkIf (cfg.settings != null) (
                  pkgs.concatTextFile {
                    name = "starship.toml";
                    files = [
                      settings
                      nerdFonts
                    ];
                  }
                ))
                (lib.mkIf (cfg.settings == null) nerdFonts)
              ];
            }
          );
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
        "fcitx5/data/quickphrase.d/emoji.mb".source = ./emoji.mb;
        "fcitx5/data/quickphrase.d/kaomoji.mb".source = ./kaomoji.mb;
        "fcitx5/data/quickphrase.d/latex.mb".source = ./latex.mb;
        "fcitx5/themes".source = pkgs.fetchFromGitHub {
          owner = "tonyfettes";
          repo = "fcitx5-nord";
          rev = "bdaa8fb723b8d0b22f237c9a60195c5f9c9d74d1";
          hash = "sha256-qVo/0ivZ5gfUP17G29CAW0MrRFUO0KN1ADl1I/rvchE=";
        };
      };
      portal = {
        enable = true;
        extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
        xdgOpenUsePortal = true;
        config.common.default = [ "gtk" ];
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
          "Xft.dpi" = config.dpi;
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
            internalBorder = dpiScale 11;
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
                Ctrl <Btn1Up>: exec-formatted("${pkgs.xdg-utils}/bin/xdg-open '%t'", PRIMARY)
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

    i18n.inputMethod.enabled = "fcitx5";

    gtk = {
      enable = true;
      theme = {
        package = pkgs.colloid-gtk-theme.override {
          tweaks = [
            "nord"
            "rimless"
          ];
        };
        name = "Colloid-Light-Nord";
      };
      iconTheme = {
        package = pkgs.colloid-icon-theme.override { schemeVariants = [ "nord" ]; };
        name = "Colloid-nord-light";
      };
      cursorTheme = {
        package =
          let
            version = "2024-02-28";
          in
          pkgs.stdenv.mkDerivation {
            inherit version;
            pname = "colloid-cursor-theme";
            src = "${
              pkgs.fetchFromGitHub {
                owner = "vinceliuice";
                repo = "Colloid-icon-theme";
                rev = version;
                hash = "sha256-bTN6x3t88yBL4WsPfOJIiNGWTywdIVi7E2VJKgMzEso=";
              }
            }/cursors";
            nativeBuildInputs = with pkgs; [
              inkscape
              xorg.xcursorgen
              jdupes
            ];
            postPatch = ''
              sed -i \
                -e 's/#000000/#2e3440/g' \
                -e 's/#1191f4/#5e81ac/g' \
                -e 's/#14adf6/#88c0d0/g' \
                -e 's/#1a1a1a/#2e3440/g' \
                -e 's/#1b9aeb/#5e81ac/g' \
                -e 's/#2a2a2a/#3b4252/g' \
                -e 's/#2c2c2c/#3b4252/g' \
                -e 's/#3bbd1c/#a3be8c/g' \
                -e 's/#4caf50/#a3be8c/g' \
                -e 's/#52cf30/#a3be8c/g' \
                -e 's/#5b9bf8/#81a1c1/g' \
                -e 's/#666666/#4c566a/g' \
                -e 's/#6fce55/#a3be8c/g' \
                -e 's/#ac44ca/#b48ead/g' \
                -e 's/#b452cb/#b48ead/g' \
                -e 's/#c7c7c7/#d8dee9/g' \
                -e 's/#ca70e1/#b48ead/g' \
                -e 's/#cecece/#d8dee9/g' \
                -e 's/#d1d1d1/#d8dee9/g' \
                -e 's/#dcdcdc/#d8dee9/g' \
                -e 's/#ed1515/#bf616a/g' \
                -e 's/#f5f5f5/#e5e9f0/g' \
                -e 's/#f67400/#d08770/g' \
                -e 's/#f83f31/#bf616a/g' \
                -e 's/#faa91e/#d08770/g' \
                -e 's/#fbb114/#d08770/g' \
                -e 's/#fbd939/#ebcb8b/g' \
                -e 's/#fdcf01/#ebcb8b/g' \
                -e 's/#ff2a2a/#bf616a/g' \
                -e 's/#ff4332/#bf616a/g' \
                -e 's/#ff645d/#bf616a/g' \
                -e 's/#ff9508/#d08770/g' \
                -e 's/#ffaa07/#d08770/g' \
                -e 's/#ffd305/#ebcb8b/g' \
                -e 's/#ffffff/#eceff4/g' \
                src/svg/*.svg \
                src/svg-white/*.svg

              patchShebangs build.sh

              substituteInPlace build.sh \
                --replace 'THEME="Colloid Cursors"' 'THEME="Colloid-nord-light-cursors"' \
                --replace 'THEME="Colloid-dark Cursors"' 'THEME="Colloid-nord-dark-cursors"'

              patchShebangs install.sh

              substituteInPlace install.sh \
                --replace '$HOME/.local' $out \
                --replace '$THEME_NAME-cursors' '$THEME_NAME-nord-light-cursors' \
                --replace '$THEME_NAME-dark-cursors' '$THEME_NAME-nord-dark-cursors'
            '';
            buildPhase = ''
              runHook preBuild
              ./build.sh
              runHook postBuild
            '';
            installPhase = ''
              runHook preInstall
              mkdir -p $out/share/icons
              ./install.sh
              jdupes --quiet --link-soft --recurse $out/share
              runHook postInstall
            '';
          };
        name = "Colloid-nord-light-cursors";
        size = dpiScale 24;
      };
      font = {
        package = pkgs.geist-font;
        name = "Geist Light";
        size = 10;
      };
      gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
    };

    qt = {
      enable = true;
      platformTheme.name = "qtct";
      style.name = "kvantum";
    };

    fonts.fontconfig.enable = true;

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
          paths = builtins.map makeDesktopItem [
            {
              name = "tailscale-systray";
              desktopName = "tailscale-systray";
              exec = "${tailscale-systray}/bin/tailscale-systray";
            }
          ];
          postBuild = ''
            files=("$out/share/applications"/*.desktop)
            mkdir -p "$out/etc/xdg/autostart"
            mv "''${files[@]}" "$out/etc/xdg/autostart"
            rm -rf "$out/share"
          '';
        })
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
        (hunspellWithDicts (with hunspellDicts; [ en_GB-ise ]))
        (nuspellWithDicts (with hunspellDicts; [ en_GB-ise ]))
        enchant
        languagetool
        webcamoid
        kdenlive
        blender
        libnotify
        file
        tree
        xsel
        xclip
        curl
        httpie
        unstable.devenv
        xdg-user-dirs
        wineWowPackages.stagingFull
        winetricks
        protontricks
        protonup
        wget
        wireshark
        websocat
        vim
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
        protonvpn-cli
        thunderbird
        neomutt
        isync
        zathura
        sigil
        (calibre.overrideAttrs (oldAttrs: {
          buildInputs = oldAttrs.buildInputs ++ (with python3Packages; [ pycryptodome ]);
        }))
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
        yubikey-manager-qt
        yubikey-personalization
        yubikey-personalization-gui
        yubioath-flutter
        pcmanfm
        lxmenu-data
        shared-mime-info
        # https://github.com/lutris/lutris/issues/3965#issuecomment-1100904672
        (lutris.overrideAttrs (oldAttrs: {
          installPhase =
            (oldAttrs.installPhase or "")
            + ''
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
        pdfchain
        hledger
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
            extraPrefs =
              (oldArgs.extraPrefs or "")
              + ''
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
                  plasma-browser-integration
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
                  plasma-browser-integration
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
                  plasma-browser-integration
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
        tor-browser-bundle-bin
        virt-manager
        virt-viewer
        qemu_full
        quickemu
        slack
        zulip
        whatsapp-for-linux
        discord
        tdesktop
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
        nix-output-monitor
        keybase
        zeal
        dasht
        codemod

        # For dark mode toggling
        xfce.xfconf

        (retroarch.override {
          cores = lib.filter (
            c: (c ? libretroCore) && (lib.meta.availableOn stdenv.hostPlatform c) && (!c.meta.unfree)
          ) (lib.attrValues libretro);
        })
        mangohud
        protonup

      ]
      ++ [

        #########
        # FONTS #
        #########

        et-book
        geist-font

        # Emoji
        # emojione
        # twitter-color-emoji
        # twemoji-color-font
        noto-fonts-emoji
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
        (
          (google-fonts.overrideAttrs (oldAttrs: {
            nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ perl ];
            installPhase =
              (oldAttrs.installPhase or "")
              + ''
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
        (league-of-moveable-type.override {
          fanwood = false;
          goudy-bookletter-1911 = false;
          knewave = false;
          league-gothic = false;
          league-script-number-one = false;
          league-spartan = false;
          linden-hill = false;
          orbitron = false;
          prociono = false;
          raleway = false;
          sniglet = false;
          sorts-mill-goudy = false;
        })

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
        (nerdfonts.override { fonts = [ "Iosevka" ]; })
        # Set FontConfig to use the symbols only font as a fallback for most
        # monospaced fonts, this gives us the symbols even for fonts that we
        # didn't install Nerd Fonts versions of. The Symbols may not be perfectly
        # suited to that font (the patched fonts usually have adjustments to the
        # Symbols specifically for that font), but it's better than nothing.
        (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
        (stdenv.mkDerivation {
          inherit (nerdfonts) version;
          pname = "nerdfonts-fontconfig";
          src = fetchurl {
            url = "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/v${nerdfonts.version}/10-nerd-font-symbols.conf";
            hash = "sha256-ZgHkMcXEPYDfzjdRR7KX3ws2u01GWUj48heMHaiaznY=";
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
        })

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
              hash = "sha256-IccB0uWWfPCidHYX6sAusuEZX906dVYo8IaqeX7/O88=";
            };
          })
          (mkAppleFont {
            name = "san-francisco-compact";
            src = pkgs.fetchurl {
              url = "https://devimages-cdn.apple.com/design/resources/download/SF-Compact.dmg";
              hash = "sha256-PlraM6SwH8sTxnVBo6Lqt9B6tAZDC//VCPwr/PNcnlk=";
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
        noto-fonts-extra
        noto-fonts-cjk-sans

      ];

    # Nicely reload system units when changing configs
    systemd.user.startServices = "sd-switch";

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    home.stateVersion = "24.11";
  };
}
