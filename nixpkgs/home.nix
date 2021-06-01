{ pkgs, config, lib, ... }:

let
  unstable = import <unstable> {
    config = { allowUnfree = true; };
    overlays = [
      # (import (builtins.fetchTarball { url = https://github.com/mjlbach/emacs-overlay/archive/feature/flakes.tar.gz; }))
      # (import (builtins.fetchTarball { url = https://github.com/nix-community/emacs-overlay/archive/master.tar.gz; }))
    ];
  };
in {
  # Overlays
  nixpkgs.overlays = [
    (import (builtins.fetchTarball { url = https://github.com/mozilla/nixpkgs-mozilla/archive/master.tar.gz; }))
    # Unstable overlay
    (final: prev: {
      emacsPackagesFor = unstable.emacsPackagesFor;
      barrier = unstable.barrier;
      fish = unstable.fish;
      flameshot = unstable.flameshot;
      gitAndTools = prev.gitAndTools // { delta = unstable.gitAndTools.delta; };
      screenkey = prev.screenkey.overridePythonAttrs (oldAttrs: rec {
        version = "1.4";
        src = final.fetchFromGitLab {
          owner = "screenkey";
          repo = "screenkey";
          rev = "v${version}";
          sha256 = "1rfngmkh01g5192pi04r1fm7vsz6hg9k3qd313sn9rl9xkjgp11l";
        };
        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ final.python38Packages.Babel ];
      });
    })
  ];

  programs.home-manager.enable = true;
  programs.man.generateCaches = true;

  home = {
    username = "zeorin";
    homeDirectory = "/home/${config.home.username}";
    sessionPath = [ "${config.xdg.configHome}/doom-emacs/bin" ];
    sessionVariables = with config.xdg; rec {
      EDITOR = "nvim";
      VISUAL = "${EDITOR}";
      LESS = "-FiRx4";
      PAGER = "less ${LESS}";

      # Help some tools actually adhere to XDG Base Dirs
      CURL_HOME = "${configHome}/curl";
      INPUTRC = "${configHome}/readline/inputrc";
      LESSKEY = "${configHome}/less/lesskey";
      NPM_CONFIG_USERCONFIG = "${configHome}/npm/npmrc";
      WEECHAT_HOME = "${configHome}/weechat";
      WGETRC = "${configHome}/wget/wgetrc";
      LESSHISTFILE = "${cacheHome}/less/history";
      PSQL_HISTORY = "${cacheHome}/pg/psql_history";
      XCOMPOSECACHE = "${cacheHome}/X11/xcompose";
      GNUPGHOME = "${dataHome}/gnupg";
      GOPATH = "${dataHome}/go";
      LEDGER_FILE = "${dataHome}/hledger.journal";
      MYSQL_HISTFILE = "${dataHome}/mysql_history";
      NODE_REPL_HISTORY = "${dataHome}/node_repl_history";
      PASSWORD_STORE_DIR = "${dataHome}/pass";
      STACK_ROOT = "${dataHome}/stack";
      WINEPREFIX = "${dataHome}/wineprefixes/default";
      DOOMDIR = "${configHome}/doom";
      DOOMLOCALDIR = "${dataHome}/doom";
    };
    activation = with config.xdg; {
      createXdgCacheAndDataDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # Cache dirs
        for dir in less pg X11; do
          $DRY_RUN_CMD mkdir --parents $VERBOSE_ARG \
            ${cacheHome}/$dir
        done

        # Data dirs
        for dir in bash go pass stack wineprefixes; do
          $DRY_RUN_CMD mkdir --parents $VERBOSE_ARG \
            ${dataHome}/$dir
        done
        $DRY_RUN_CMD mkdir --parents $VERBOSE_ARG \
          --mode=700 ${dataHome}/gnupg
      '';
    };
  };

  programs = {
    bash.enable = true;
    dircolors = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      extraConfig = ''
        # Exact Solarized color theme for the color GNU ls utility.
        # Designed for dircolors (GNU coreutils) 5.97
        #
        # This simple theme was simultaneously designed for these terminal color schemes:
        # - Solarized dark  (best)
        # - Solarized light (best)
        # - default dark
        # - default light
        #
        # How the colors were selected:
        # - Terminal emulators often have an option typically enabled by default that makes
        #   bold a different color.  It is important to leave this option enabled so that
        #   you can access the entire 16-color Solarized palette, and not just 8 colors.
        # - We favor universality over a greater number of colors.  So we limit the number
        #   of colors so that this theme will work out of the box in all terminals,
        #   Solarized or not, dark or light.
        # - We choose to have the following category of files:
        #   NORMAL & FILE, DIR, LINK, EXEC and
        #   editable text including source, unimportant text, binary docs & multimedia source
        #   files, viewable multimedia, archived/compressed, and unimportant non-text
        # - For uniqueness, we stay away from the Solarized foreground colors are -- either
        #   base00 (brightyellow) or base0 (brightblue).  However, they can be used if
        #   you know what the bg/fg colors of your terminal are, in order to optimize the display.
        # - 3 different options are provided: universal, solarized dark, and solarized light.
        #   The only difference between the universal scheme and one that's optimized for
        #   dark/light is the color of "unimportant" files, which should blend more with the
        #   background
        # - We note that blue is the hardest color to see on dark bg and yellow is the hardest
        #   color to see on light bg (with blue being particularly bad).  So we choose yellow
        #   for multimedia files which are usually accessed in a GUI folder browser anyway.
        #   And blue is kept for custom use of this scheme's user.
        # - See table below to see the assignments.


        # Installation instructions:
        # This file goes in the /etc directory, and must be world readable.
        # You can copy this file to .dir_colors in your $HOME directory to override
        # the system defaults.

        # COLOR needs one of these arguments: 'tty' colorizes output to ttys, but not
        # pipes. 'all' adds color characters to all output. 'none' shuts colorization
        # off.
        COLOR tty

        # Below, there should be one TERM entry for each termtype that is colorizable
        TERM ansi
        TERM color_xterm
        TERM color-xterm
        TERM con132x25
        TERM con132x30
        TERM con132x43
        TERM con132x60
        TERM con80x25
        TERM con80x28
        TERM con80x30
        TERM con80x43
        TERM con80x50
        TERM con80x60
        TERM cons25
        TERM console
        TERM cygwin
        TERM dtterm
        TERM dvtm
        TERM dvtm-256color
        TERM Eterm
        TERM eterm-color
        TERM fbterm
        TERM gnome
        TERM gnome-256color
        TERM jfbterm
        TERM konsole
        TERM konsole-256color
        TERM kterm
        TERM linux
        TERM linux-c
        TERM mach-color
        TERM mlterm
        TERM nxterm
        TERM putty
        TERM putty-256color
        TERM rxvt
        TERM rxvt-256color
        TERM rxvt-cygwin
        TERM rxvt-cygwin-native
        TERM rxvt-unicode
        TERM rxvt-unicode256
        TERM rxvt-unicode-256color
        TERM screen
        TERM screen-16color
        TERM screen-16color-bce
        TERM screen-16color-s
        TERM screen-16color-bce-s
        TERM screen-256color
        TERM screen-256color-bce
        TERM screen-256color-s
        TERM screen-256color-bce-s
        TERM screen-256color-italic
        TERM screen-bce
        TERM screen-w
        TERM screen.xterm-256color
        TERM screen.linux
        TERM screen.xterm-new
        TERM st
        TERM st-meta
        TERM st-256color
        TERM st-meta-256color
        TERM tmux
        TERM tmux-256color
        TERM vt100
        TERM xterm
        TERM xterm-new
        TERM xterm-16color
        TERM xterm-256color
        TERM xterm-256color-italic
        TERM xterm-88color
        TERM xterm-color
        TERM xterm-debian
        TERM xterm-termite

        # EIGHTBIT, followed by '1' for on, '0' for off. (8-bit output)
        EIGHTBIT 1

        #############################################################################
        # Below are the color init strings for the basic file types. A color init
        # string consists of one or more of the following numeric codes:
        #
        # Attribute codes:
        #   00=none 01=bold 04=underscore 05=blink 07=reverse 08=concealed
        # Text color codes:
        #   30=black 31=red 32=green 33=yellow 34=blue 35=magenta 36=cyan 37=white
        # Background color codes:
        #   40=black 41=red 42=green 43=yellow 44=blue 45=magenta 46=cyan 47=white
        #
        # NOTES:
        # - See http://www.oreilly.com/catalog/wdnut/excerpt/color_names.html
        # - Color combinations
        #   ANSI Color code       Solarized  Notes                Universal             SolDark              SolLight
        #   ~~~~~~~~~~~~~~~       ~~~~~~~~~  ~~~~~                ~~~~~~~~~             ~~~~~~~              ~~~~~~~~
        #   00    none                                            NORMAL, FILE          <SAME>               <SAME>
        #   30    black           base02
        #   01;30 bright black    base03     bg of SolDark
        #   31    red             red                             docs & mm src         <SAME>               <SAME>
        #   01;31 bright red      orange                          EXEC                  <SAME>               <SAME>
        #   32    green           green                           editable text         <SAME>               <SAME>
        #   01;32 bright green    base01                          unimportant text      <SAME>
        #   33    yellow          yellow     unclear in light bg  multimedia            <SAME>               <SAME>
        #   01;33 bright yellow   base00     fg of SolLight                             unimportant non-text
        #   34    blue            blue       unclear in dark bg   user customized       <SAME>               <SAME>
        #   01;34 bright blue     base0      fg in SolDark                                                   unimportant text
        #   35    magenta         magenta                         LINK                  <SAME>               <SAME>
        #   01;35 bright magenta  violet                          archive/compressed    <SAME>               <SAME>
        #   36    cyan            cyan                            DIR                   <SAME>               <SAME>
        #   01;36 bright cyan     base1                           unimportant non-text                       <SAME>
        #   37    white           base2
        #   01;37 bright white    base3      bg in SolLight
        #   05;37;41                         unclear in Putty dark


        ### By file type

        # global default
        NORMAL 00
        # normal file
        FILE 00
        # directory
        DIR 36
        # symbolic link
        LINK 35

        # pipe, socket, block device, character device (blue bg)
        FIFO 30;44
        SOCK 35;44
        DOOR 35;44 # Solaris 2.5 and later
        BLK  33;44
        CHR  37;44


        #############################################################################
        ### By file attributes

        # Orphaned symlinks (blinking white on red)
        # Blink may or may not work (works on iTerm dark or light, and Putty dark)
        ORPHAN  05;37;41
        # ... and the files that orphaned symlinks point to (blinking white on red)
        MISSING 05;37;41

        # files with execute permission
        EXEC 01;31  # Unix
        .cmd 01;31  # Win
        .exe 01;31  # Win
        .com 01;31  # Win
        .bat 01;31  # Win
        .reg 01;31  # Win
        .app 01;31  # OSX

        #############################################################################
        ### By extension

        # List any file extensions like '.gz' or '.tar' that you would like ls
        # to colorize below. Put the extension, a space, and the color init string.
        # (and any comments you want to add after a '#')

        ### Text formats

        # Text that we can edit with a regular editor
        .txt 32
        .org 32
        .md 32
        .mkd 32

        # Source text
        .h 32
        .hpp 32
        .c 32
        .C 32
        .cc 32
        .cpp 32
        .cxx 32
        .objc 32
        .cl 32
        .sh 32
        .bash 32
        .csh 32
        .zsh 32
        .el 32
        .vim 32
        .java 32
        .pl 32
        .pm 32
        .py 32
        .rb 32
        .hs 32
        .php 32
        .htm 32
        .html 32
        .shtml 32
        .erb 32
        .haml 32
        .xml 32
        .rdf 32
        .css 32
        .sass 32
        .scss 32
        .less 32
        .js 32
        .coffee 32
        .man 32
        .0 32
        .1 32
        .2 32
        .3 32
        .4 32
        .5 32
        .6 32
        .7 32
        .8 32
        .9 32
        .l 32
        .n 32
        .p 32
        .pod 32
        .tex 32
        .go 32
        .sql 32
        .csv 32

        ### Multimedia formats

        # Image
        .bmp 33
        .cgm 33
        .dl 33
        .dvi 33
        .emf 33
        .eps 33
        .gif 33
        .jpeg 33
        .jpg 33
        .JPG 33
        .mng 33
        .pbm 33
        .pcx 33
        .pdf 33
        .pgm 33
        .png 33
        .PNG 33
        .ppm 33
        .pps 33
        .ppsx 33
        .ps 33
        .svg 33
        .svgz 33
        .tga 33
        .tif 33
        .tiff 33
        .xbm 33
        .xcf 33
        .xpm 33
        .xwd 33
        .xwd 33
        .yuv 33

        # Audio
        .aac 33
        .au  33
        .flac 33
        .m4a 33
        .mid 33
        .midi 33
        .mka 33
        .mp3 33
        .mpa 33
        .mpeg 33
        .mpg 33
        .ogg  33
        .opus 33
        .ra 33
        .wav 33

        # Video
        .anx 33
        .asf 33
        .avi 33
        .axv 33
        .flc 33
        .fli 33
        .flv 33
        .gl 33
        .m2v 33
        .m4v 33
        .mkv 33
        .mov 33
        .MOV 33
        .mp4 33
        .mp4v 33
        .mpeg 33
        .mpg 33
        .nuv 33
        .ogm 33
        .ogv 33
        .ogx 33
        .qt 33
        .rm 33
        .rmvb 33
        .swf 33
        .vob 33
        .webm 33
        .wmv 33

        ### Misc

        # Binary document formats and multimedia source
        .doc 31
        .docx 31
        .rtf 31
        .odt 31
        .dot 31
        .dotx 31
        .ott 31
        .xls 31
        .xlsx 31
        .ods 31
        .ots 31
        .ppt 31
        .pptx 31
        .odp 31
        .otp 31
        .fla 31
        .psd 31

        # Archives, compressed
        .7z   1;35
        .apk  1;35
        .arj  1;35
        .bin  1;35
        .bz   1;35
        .bz2  1;35
        .cab  1;35  # Win
        .deb  1;35
        .dmg  1;35  # OSX
        .gem  1;35
        .gz   1;35
        .iso  1;35
        .jar  1;35
        .msi  1;35  # Win
        .rar  1;35
        .rpm  1;35
        .tar  1;35
        .tbz  1;35
        .tbz2 1;35
        .tgz  1;35
        .tx   1;35
        .war  1;35
        .xpi  1;35
        .xz   1;35
        .z    1;35
        .Z    1;35
        .zip  1;35

        # For testing
        .ANSI-30-black 30
        .ANSI-01;30-brblack 01;30
        .ANSI-31-red 31
        .ANSI-01;31-brred 01;31
        .ANSI-32-green 32
        .ANSI-01;32-brgreen 01;32
        .ANSI-33-yellow 33
        .ANSI-01;33-bryellow 01;33
        .ANSI-34-blue 34
        .ANSI-01;34-brblue 01;34
        .ANSI-35-magenta 35
        .ANSI-01;35-brmagenta 01;35
        .ANSI-36-cyan 36
        .ANSI-01;36-brcyan 01;36
        .ANSI-37-white 37
        .ANSI-01;37-brwhite 01;37

        #############################################################################
        # Your customizations

        # Unimportant text files
        # For universal scheme, use brightgreen 01;32
        # For optimal on light bg (but too prominent on dark bg), use white 01;34
        .log 01;32
        *~ 01;32
        *# 01;32
        #.log 01;34
        #*~ 01;34
        #*# 01;34

        # Unimportant non-text files
        # For universal scheme, use brightcyan 01;36
        # For optimal on dark bg (but too prominent on light bg), change to 01;33
        .bak 01;36
        .BAK 01;36
        .old 01;36
        .OLD 01;36
        .org_archive 01;36
        .off 01;36
        .OFF 01;36
        .dist 01;36
        .DIST 01;36
        .orig 01;36
        .ORIG 01;36
        .swp 01;36
        .swo 01;36
        *,v 01;36
        #.bak 01;33
        #.BAK 01;33
        #.old 01;33
        #.OLD 01;33
        #.org_archive 01;33
        #.off 01;33
        #.OFF 01;33
        #.dist 01;33
        #.DIST 01;33
        #.orig 01;33
        #.ORIG 01;33
        #.swp 01;33
        #.swo 01;33
        #*,v 01;33

        # The brightmagenta (Solarized: purple) color is free for you to use for your
        # custom file type
        .gpg 34
        .gpg 34
        .pgp 34
        .asc 34
        .3des 34
        .aes 34
        .enc 34
        .sqlite 34
      '';
    };
    direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      enableNixDirenvIntegration = true;
    };
    emacs = {
      enable = true;
      package = let
        # emacsPkg = unstable.emacsPgtkGcc;
        emacsPkg = unstable.emacs;
      in with pkgs; (symlinkJoin {
        name = "emacs";
        paths = [ emacsPkg ];
        buildInputs = [ makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/emacs \
            --prefix PATH : "${binutils}/bin" \
            --prefix PATH : "${ripgrep.override { withPCRE2 = true; }}/bin" \
            --prefix PATH : "${gnutls}/bin" \
            --prefix PATH : "${fd}/bin" \
            --prefix PATH : "${imagemagick}/bin" \
            --prefix PATH : "${zstd}/bin" \
            --prefix PATH : "${nodePackages.javascript-typescript-langserver}/bin" \
            --prefix PATH : "${sqlite}/bin" \
            --prefix PATH : "${editorconfig-core-c}/bin"
        '';
      }) // (with emacsPkg; {
        inherit meta src;
      });
      extraPackages = epkgs: (with epkgs; [
        vterm
      ]);
    };
    firefox = {
      enable = true;
      package = pkgs.latest.firefox-bin;
    };
    fish = {
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
        ls = "${pkgs.lsd}/bin/lsd";
        l = "ls -lFh";     #size,show type,human readable
        la = "ls -lAFh";   #long list,show almost all,show type,human readable
        lr = "ls -tRFh";   #sorted by date,recursive,show type,human readable
        lt = "ls -ltFh";   #long list,sorted by date,show type,human readable
        ll = "ls -l";      #long list
        ldot = "ls -ld .*";
        lS = "ls -1FSsh";
        lart = "ls -1Fcart";
        lrt = "ls -1Fcrt";
        tree = "${pkgs.lsd}/bin/lsd --tree";
        cat = "${pkgs.bat}/bin/bat";
        grep = "grep --color=auto";
        sgrep = "grep -R -n -H -C 5 --exclude-dir={.git,.svn,CVS}";
        hgrep = "fc -El 0 | grep";
        todo =
          "${pkgs.todo-txt-cli}/bin/todo.sh -d ${config.xdg.configHome}/todo/config";
        dud = "du -d 1 -h";
        duf = "du -sh *";
        fd = "find . -type d -name";
        ff = "find . -type f -name";
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
        test -e ~/.tmux/session_chooser.fish && source ~/.tmux/session_chooser.fish

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
          if test "$COLUMNS" -ge 120; and ! contains side-by-side "$DELTA_FEATURES"
            set --global --export --append DELTA_FEATURES side-by-side
          else if test "$COLUMNS" -lt 120; and contains side-by-side "$DELTA_FEATURES"
            set --erase DELTA_FEATURES[(contains --index side-by-side "$DELTA_FEATURES")]
          end
        end
        delta_sidebyside

        function __fish_command_not_found_handler --on-event fish_command_not_found
          ${pkgs.writeShellScript "nix-command-not-found" ''
            source ${pkgs.nix-index}/etc/profile.d/command-not-found.sh
            command_not_found_handle "$@"
          ''} $argv
        end
      '';
    };
    git = {
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
        "difftool \"nvimdiff\"".cmd = ''$VISUAL -d "$LOCAL" "$REMOTE"'';
        merge = {
          stat = true;
          tool = "nvimdiff";
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
          path = "~/Code/John Lewis/.gitconfig";
          condition = "gitdir:~/Code/John Lewis/";
        }
      ];
      delta = {
        enable = true;
        options = {
          features = "line-numbers decorations";
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
        c = ''
          !f() { if command -v git-cz >/dev/null 2>&1; then git-cz "$@"; else git commit "$@"; fi; }; f'';
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
        edit-dirty =
          "!git status --porcelain | ${pkgs.gnused}/bin/sed s/^...// | xargs $EDITOR";
        tracked-ignores = "!git ls-files | git check-ignore --no-index --stdin";
        # https://www.erikschierboom.com/2020/02/17/cleaning-up-local-git-branches-deleted-on-a-remote/
        rm-gone = ''
          !git for-each-ref --format '%(refname:short) %(upstream:track)' | ${pkgs.gawk}/bin/awk '$2 == "[gone]" {print $1}' | ${pkgs.findutils}/bin/xargs -r git branch -D'';
        # https://stackoverflow.com/a/34467298
        l = "!git lg";
        lg = "!git lg1";
        lg1 =
          "!git lg1-specific --branches --decorate-refs-exclude=refs/remotes/*";
        lg2 =
          "!git lg2-specific --branches --decorate-refs-exclude=refs/remotes/*";
        lg3 =
          "!git lg3-specific --branches --decorate-refs-exclude=refs/remotes/*";
        lg-all = "!git lg1-all";
        lg1-all = "!git lg1-specific --all";
        lg2-all = "!git lg2-specific --all";
        lg3-all = "!git lg3-specific --all";
        lg-specific = "!git lg1-specific";
        lg1-specific =
          "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'";
        lg2-specific =
          "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'";
        lg3-specific =
          "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset) %C(bold cyan)(committed: %cD)%C(reset) %C(auto)%d%C(reset)%n''          %C(white)%s%C(reset)%n''          %C(dim white)- %an <%ae> %C(reset) %C(dim white)(committer: %cn <%ce>)%C(reset)'";
        # https://docs.gitignore.io/use/command-line
        ignore =
          "!gi() { ${pkgs.curl}/bin/curl -sL https://www.gitignore.io/api/$@ 2>/dev/null ;}; gi";
      };
      ignores =
        [ "*~" "*.swp" "*.swo" ".DS_Store" "tags" "Session.vim" "/.vim" ];
    };
    gpg.enable = true;
    htop.enable = true;
    mpv = {
      enable = true;
      config = {
        hwdec = "auto-safe";
        vo = "gpu";
        profile = "gpu-hq";
      };
    };
    starship = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
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
              rev = "de8ac3e8a9fa887382649784ed8cae81f5757f77";
              sha256 = "0mkp9r6mipdm7408w7ls1vfn6i3hj19nmir2bvfcp12b69zlzc47";
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
    zathura = {
      enable = true;
      options = {
        # Use the title bar for status
        guioptions = "";
        window-title-basename = true;
        window-title-page  = true;

        # Better dark mode
        recolor-darkcolor = "\#CCCCCC";
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
          font = "Iosevka Term 12";
          allow_markup = true;
          format = ''
            <b>%s</b>
            %b'';
          sort = true;
          indicate_hidden = true;
          alignment = true;
          bounce_freq = 0;
          show_age_threshold = 60;
          word_wrap = true;
          ignore_newline = false;
          geometry = "800x10-0+48";
          max_icon_size = 60;
          shrink = true;
          transparency = 15;
          idle_threshold = 0;
          monitor = 0;
          follow = "keyboard";
          sticky_history = true;
          history_length = 20;
          show_indicators = true;
          line_height = 0;
          separator_height = 0;
          padding = 12;
          horizontal_padding = 12;
          separator_color = "frame";
          startup_notification = false;
          dmenu = "${pkgs.rofi}/bin/rofi -dmenu -p dunst";
          browser = "${config.programs.firefox.package}/bin/firefox -new-tab";
          icon_position = "left";
          icon_folders =
            "${pkgs.arc-icon-theme}/share/icons/Arc/status/32@2x/:${pkgs.arc-icon-theme}/share/icons/Arc/devices/32@2x/:${pkgs.arc-icon-theme}/share/icons/Arc/legacy/32@2x/";
        };
        frame = {
          width = 0;
          color = "#aaaaaa";
        };
        shortcuts = {
          close = "mod4+dollar";
          close_all = "mod4+shift+dollar";
          history = "mod4+ampersand";
          context = "mod4+m";
        };
        urgency_low = {
          background = "#002b36";
          foreground = "#586e75";
          timeout = 10;
        };
        urgency_normal = {
          background = "#268bd2";
          foreground = "#eee8d5";
          timeout = 10;
        };
        urgency_critical = {
          background = "#dc322f";
          foreground = "#fdf6e3";
          timeout = 0;
        };
      };
    };
    emacs = {
      enable = true;
      client.enable = true;
    };
    flameshot.enable = true;
    gpg-agent = {
      enable = true;
      pinentryFlavor = "gnome3";
    };
    lorri.enable = true;
    network-manager-applet.enable = true;
    nextcloud-client.enable = true;
    picom = {
      enable = true;
      backend = "xrender";
      fade = true;
      fadeDelta = 3;
      inactiveOpacity = "0.9";
      inactiveDim = "0.1";
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
        # no shadow on stacked / tabbed windows
        "_NET_WM_STATE@[0]:a = '_NET_WM_STATE@_MAXIMIZED_VERT'"
        "_NET_WM_STATE@[0]:a = '_NET_WM_STATE@_MAXIMIZED_HORZ'"
        "_GTK_FRAME_EXTENTS@:c"
      ];
      vSync = true;
      extraOptions = ''
        mark-wmwin-focused = true;
        mark-ovredir-focused = true;
        detect-rounded-corners = true;
        detect-client-opacity = true;
        detect-transient = true;
        glx-no-stencil = true
        glx-no-rebind-pixmap = true;
        use-damage = true;
        shadow-radius = 7;
        xinerama-shadow-crop = true;
        focus-exclude = [
          "name = 'Picture-in-Picture'"
        ];
      '';
    };
    redshift = {
      enable = true;
      tray = true;
      provider = "manual";
      latitude = "-26.20";
      longitude = "28.02";
      extraOptions = [ "-v" "-m randr" ];
    };
    unclutter = {
      enable = true;
      threshold = 10;
      extraOptions = [ "ignore-scrolling" ];
    };
  };

  # # Email
  # programs.mbsync.enable = true;
  # programs.msmtp.enable = true;
  # accounts.email = {
  #   maildirBasePath = "$HOME/.mail";
  #   accounts = {
  #     personal = {
  #       primary = true;
  #       address = "me@xandor.co.za";
  #       username = address;
  #       realName = "Xandor Schiefer";
  #       signature = {
  #         showSignature = "append";
  #         text = ''
  #           --
  #           Xandor Schiefer
  #         '';
  #       };
  #       imap = {
  #         host = "mail.xandor.co.za";
  #         tls.enable = true;
  #         imapnotify = {
  #           enable = true;
  #           boxes = [ "Inbox" ];
  #           onNotify = "${pkgs.isync}/bin/mbsync ${name}";
  #           onNotifyPost.mail = "${pkgs.libnotify}/bin/notify-send --urgency=low 'New mail arrived for ${name}'";
  #         };
  #       };
  #       mbsync = {
  #         enable = true;
  #         create = "both";
  #         expunge = "both";
  #         remove = "both";
  #       };
  #     };
  #     gmail = {
  #       address = "zeorin@gmail.com";
  #       username = address;
  #       realName = "Xandor Schiefer";
  #       signature = {
  #         showSignature = "append";
  #         text = ''
  #           --
  #           Xandor Schiefer
  #         '';
  #       };
  #       flavor = "gmail.com";
  #       imap = {
  #         host = "imap.gmail.com";
  #         tls.enable = true;
  #         imapnotify = {
  #           enable = true;
  #           boxes = [ "Inbox" ];
  #           onNotify = "${pkgs.isync}/bin/mbsync ${name}";
  #           onNotifyPost.mail = "${pkgs.libnotify}/bin/notify-send --urgency=low 'New mail arrived for ${name}'";
  #         };
  #       };
  #       mbsync = {
  #         enable = true;
  #         create = "both";
  #         expunge = "both";
  #         remove = "both";
  #       };
  #     };
  #     pixeltheory = {
  #       address = "xandor@pixeltheory.dev";
  #       username = address;
  #       realName = "Xandor Schiefer";
  #       signature = {
  #         showSignature = "append";
  #         text = ''
  #           --
  #           Xandor Schiefer
  #           Director
  #           Pixel Theory
  #           +27 79 706 5620
  #         '';
  #       };
  #       flavor = "gmail.com";
  #       imap = {
  #         host = "imap.gmail.com";
  #         tls.enable = true;
  #         imapnotify = {
  #           enable = true;
  #           boxes = [ "Inbox" ];
  #           onNotify = "${pkgs.isync}/bin/mbsync ${name}";
  #           onNotifyPost.mail = "${pkgs.libnotify}/bin/notify-send --urgency=low 'New mail arrived for ${name}'";
  #         };
  #       };
  #       mbsync = {
  #         enable = true;
  #         create = "both";
  #         expunge = "both";
  #         remove = "both";
  #       };
  #     };
  #   };
  # };

  # Allow for bluetooth devices to interface with MPRIS
  systemd.user.services.mpris-proxy = {
    Unit = {
      Description = "Forward bluetooth media controls to MPRIS";
      After = [ "network.target" "sound.target" ];
    };
    Service.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
    Install.WantedBy = [ "default.target" ];
  };

  xdg = {
    enable = true;
    userDirs.enable = true;
    configFile = with config.xdg; {
      "bat/config".text = ''
        --theme="Solarized (dark)"
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
        source = builtins.fetchGit "https://github.com/hlissner/doom-emacs";
        onChange = "${pkgs.writeShellScript "doom-change" ''
          export DOOMDIR="${config.home.sessionVariables.DOOMDIR}"
          export DOOMLOCALDIR="${config.home.sessionVariables.DOOMLOCALDIR}"
          if [ ! -d "$DOOMLOCALDIR" ]; then
            ${configHome}/doom-emacs/bin/doom -y install
          else
            ${configHome}/doom-emacs/bin/doom -y clean
            ${configHome}/doom-emacs/bin/doom -y sync -u
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
        (setq doom-font (font-spec :family "Iosevka Term" :size 12 :weight 'semi-light)
              doom-variable-pitch-font (font-spec :family "sans" :size 13))

        ;; There are two ways to load a theme. Both assume the theme is installed and
        ;; available. You can either set `doom-theme' or manually load a theme with the
        ;; `load-theme' function. This is the default:
        (setq doom-theme 'doom-nord)

        ;; If you use `org' and don't want your org files in the default location below,
        ;; change `org-directory'. It must be set before org loads!
        (setq org-directory "~/Documents/org")
        (setq org-roam-directory "~/Documents/org-roam")

        ;; This determines the style of line numbers in effect. If set to `nil', line
        ;; numbers are disabled. For relative line numbers, set this to `relative'.
        (setq display-line-numbers-type 'relative)

        (setq projectile-project-search-path '("~/Code/"
                                              "~/Code/Stone Three/"
                                              "~/Code/Pixel Theory/"
                                              "~/Code/John Lewis/"
                                              "~/Code/TransferGo/"))

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
                 (emoji +unicode)  ; 🙂
                 ;;fill-column       ; a `fill-column' indicator
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
                 treemacs          ; a project drawer, like neotree but cooler
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
                 ;;(format +onsave)  ; automated prettiness
                 ;;god               ; run Emacs commands without modifier keys
                 ;;lispy             ; vim for lisp, for people who don't like vim
                 ;;multiple-cursors  ; editing in many places at once
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
                 syntax              ; tasing you for every semicolon you forget
                 (spell +flyspell) ; tasing you for misspelling mispelling
                 grammar           ; tasing grammar mistake every you make

                 :tools
                 ;;ansible
                 ;;debugger          ; FIXME stepping through code, to help you add bugs
                 direnv
                 docker
                 editorconfig      ; let someone else argue about tabs vs spaces
                 ;;ein               ; tame Jupyter notebooks with emacs
                 (eval +overlay)     ; run code, run (also, repls)
                 ;;gist              ; interacting with github gists
                 lookup              ; navigate your code and its documentation
                 lsp
                 magit             ; a git porcelain for Emacs
                 ;;make              ; run make tasks from Emacs
                 pass              ; password manager for nerds
                 ;;pdf               ; pdf enhancements
                 ;;prodigy           ; FIXME managing external services & code builders
                 rgb               ; creating color strings
                 ;;taskrunner        ; taskrunner for all your projects
                 ;;terraform         ; infrastructure as code
                 tmux              ; an API for interacting with tmux
                 ;;upload            ; map local to remote projects via ssh/ftp

                 :os
                 (:if IS-MAC macos)  ; improve compatibility with macOS
                 ;;tty               ; improve the terminal Emacs experience

                 :lang
                 ;;agda              ; types of types of types of types...
                 cc                ; C/C++/Obj-C madness
                 clojure           ; java with a lisp
                 common-lisp       ; if you've seen one lisp, you've seen them all
                 ;;coq               ; proofs-as-programs
                 ;;crystal           ; ruby at the speed of c
                 ;;csharp            ; unity, .NET, and mono shenanigans
                 ;;data              ; config/data formats
                 (dart +flutter)   ; paint ui and not much else
                 elixir            ; erlang done right
                 elm               ; care for a cup of TEA?
                 emacs-lisp        ; drown in parentheses
                 ;;erlang            ; an elegant language for a more civilized age
                 ;;ess               ; emacs speaks statistics
                 ;;faust             ; dsp, but you get to keep your soul
                 fsharp            ; ML stands for Microsoft's Language
                 ;;fstar             ; (dependent) types and (monadic) effects and Z3
                 ;;gdscript          ; the language you waited for
                 (go +lsp)         ; the hipster dialect
                 (haskell +dante)  ; a language that's lazier than I am
                 ;;hy                ; readability of scheme w/ speed of python
                 ;;idris             ; a language you can depend on
                 json              ; At least it ain't XML
                 ;;(java +meghanada) ; the poster child for carpal tunnel syndrome
                 javascript        ; all(hope(abandon(ye(who(enter(here))))))
                 ;;julia             ; a better, faster MATLAB
                 ;;kotlin            ; a better, slicker Java(Script)
                 latex             ; writing papers in Emacs has never been so fun
                 ;;lean
                 ;;factor
                 ledger            ; an accounting system in Emacs
                 ;;lua               ; one-based indices? one-based indices
                 markdown          ; writing docs for people to ignore
                 ;;nim               ; python + lisp at the speed of c
                 nix               ; I hereby declare "nix geht mehr!"
                 ocaml             ; an objective camel
                 (org               ; organize your plain life in plain text
                  +pretty
                  +roam)
                 php               ; perl's insecure younger brother
                 ;;plantuml          ; diagrams for confusing people more
                 ;;purescript        ; javascript, but functional
                 python            ; beautiful is better than ugly
                 ;;qt                ; the 'cutest' gui framework ever
                 ;;racket            ; a DSL for DSLs
                 ;;raku              ; the artist formerly known as perl6
                 ;;rest              ; Emacs as a REST client
                 ;;rst               ; ReST in peace
                 (ruby +rails)     ; 1.step {|i| p "Ruby is #{i.even? ? 'love' : 'life'}"}
                 rust              ; Fe2O3.unwrap().unwrap().unwrap().unwrap()
                 scala             ; java, but good
                 scheme            ; a fully conniving family of lisps
                 sh                ; she sells {ba,z,fi}sh shells on the C xor
                 ;;sml
                 ;;solidity          ; do you need a blockchain? No.
                 ;;swift             ; who asked for emoji variables?
                 ;;terra             ; Earth and Moon in alignment for performance.
                 web               ; the tubes
                 yaml              ; JSON, but readable

                 :email
                 ;;(mu4e +gmail)
                 ;;notmuch
                 ;;(wanderlust +gmail)

                 :app
                 ;;calendar
                 ;;emms
                 ;;everywhere        ; *leave* Emacs!? You must be joking
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
          ${configHome}/doom-emacs/bin/doom -y sync
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
        '';
        onChange = "${pkgs.writeShellScript "doom-config-packages-change" ''
          export DOOMDIR="${config.home.sessionVariables.DOOMDIR}"
          export DOOMLOCALDIR="${config.home.sessionVariables.DOOMLOCALDIR}"
          ${configHome}/doom-emacs/bin/doom -y sync
        ''}";
      };
      emacs.source = pkgs.fetchFromGitHub {
        owner = "plexus";
        repo = "chemacs2";
        rev = "30a20dbc2799e4ab2f8c509fdadcd90aa9845b5c";
        sha256 = "0ghry3v05y31vgpwr2hc4gzn8s6sr6fvqh88fsnj9448lrim38f9";
      };
      "jrln/jrln.yaml".text = ''
        default_hour: 9
        timeformat: "%Y-%m-%d %H:%M"
        linewrap: 79
        encrypt: false
        editor: nvim
        default_minute: 0,
        highlight: true,
        journals:
          default: ${userDirs.documents}/Journal/journal.txt
        tagsymbols: @
      '';
      "flameshot/flameshot.ini".text = ''
        [General]
        contrastOpacity=127
        contrastUiColor=#4476ff
        copyAndCloseAfterUpload=true
        disabledTrayIcon=true
        drawColor=#1e6cc5
        drawThickness=2
        saveAfterCopyPath=/home/zeorin/Screenshots
        savePath=/home/zeorin/Screenshots/
        showHelp=false
        uiColor=#003396
      '';
      "flameshot/flameshot.sh".source = pkgs.writeShellScript "flameshot.sh" ''
        if [ "$1" = "activewindow" ]; then
          # Get active window geometry
          eval $(${pkgs.xdotool}/bin/xdotool getactivewindow getwindowgeometry --shell)
        elif [ "$1" = "selectwindow" ]; then
          # Let the user select a window and get its geometry
          eval $(${pkgs.xdotool}/bin/xdotool selectwindow getwindowgeometry --shell)
        else
          # Get screen geometry
          WIDTH=$(${pkgs.xorg.xrandr}/bin/xrandr --query | ${pkgs.gawk}/bin/awk -F '[ x,+]' '/\<connected\>/{print $3}')
          HEIGHT=$(${pkgs.xorg.xrandr}/bin/xrandr --query | ${pkgs.gawk}/bin/awk -F '[ x,+]' '/\<connected\>/{print $4}')
          X=0
          Y=0
        fi

        # Get mouse position
        eval $(echo $(${pkgs.xdotool}/bin/xdotool getmouselocation --shell) | ${pkgs.gnused}/bin/sed "s/\(X\|Y\)/MOUSE\1/g")

        # Launch the screenshot gui
        ${pkgs.flameshot}/bin/flameshot gui && sleep 0.3

        # Move the mouse to the top left corner and drag it to to the right bottom corner
        ${pkgs.xdotool}/bin/xdotool mousemove $X $Y
        ${pkgs.xdotool}/bin/xdotool mousedown 1 # press and hold
        ${pkgs.xdotool}/bin/xdotool mousemove_relative $WIDTH $HEIGHT
        ${pkgs.xdotool}/bin/xdotool mouseup 1 # release

        # Restore mouse to previous location
        ${pkgs.xdotool}/bin/xdotool mousemove $MOUSEX $MOUSEY
      '';
      "less/lesskey".source = pkgs.runCommand "lesskey" { }
        "${pkgs.less}/bin/lesskey --output $out ${
          pkgs.writeText "lesskey_input" ''
            #line-edit
            ^P  up
            ^N  down
          ''
        }";
      "npm/npmrc".text = ''
        init-author-name=Xandor Schiefer
        init-author-email=me@xandor.co.za
        init-version=0.0.0
        init-license=LGPL-3.0
        prefix=${dataHome}/npm
        cache=${cacheHome}/npm
        tmp=$XDG_RUNTIME_DIR/npm
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
      "rofi/config.rasi".text = ''
        configuration {
            modi: "window,run,ssh";
            width: 50;
            lines: 15;
            columns: 1;
            font: "Iosevka Term 12";
            bw: 1;
            location: 0;
            padding: 5;
            yoffset: 0;
            xoffset: 0;
            fixed-num-lines: true;
            show-icons: true;
            terminal: "rofi-sensible-terminal";
            ssh-client: "ssh";
            ssh-command: "{terminal} -e {ssh-client} {host} [-p {port}]";
            run-command: "{cmd}";
            run-list-command: "";
            run-shell-command: "{terminal} -e {cmd}";
            window-command: "wmctrl -i -R {window}";
            window-match-fields: "all";
            /* icon-theme: ; */
            drun-match-fields: "name,generic,exec,categories";
            drun-show-actions: false;
            /* drun-display-format: "{name} [<span weight='light' size='small'><i>({generic})</i></span>]"; */
            drun-display-format: "{name}";
            disable-history: false;
            ignored-prefixes: "";
            sort: false;
            /* sorting-method: ; */
            case-sensitive: false;
            cycle: true;
            sidebar-mode: false;
            eh: 1;
            auto-select: false;
            parse-hosts: false;
            parse-known-hosts: true;
            combi-modi: "window,run";
            matching: "normal";
            tokenize: true;
            m: "-5";
            line-margin: 2;
            line-padding: 1;
            /* filter: ; */
            separator-style: "dash";
            hide-scrollbar: false;
            fullscreen: false;
            fake-transparency: false;
            dpi: -1;
            threads: 0;
            scrollbar-width: 8;
            scroll-method: 0;
            fake-background: "screenshot";
            window-format: "{w}    {c}   {t}";
            click-to-exit: true;
            show-match: true;
            /* theme: ; */
            /* color-normal: ; */
            /* color-urgent: ; */
            /* color-active: ; */
            /* color-window: ; */
            max-history-size: 25;
            combi-hide-mode-prefix: false;
            // matching-negate-char: '-' /* unsupported */;
            /* cache-dir: ; */
            pid: "/run/user/1000/rofi.pid";
            /* display-window: ; */
            /* display-windowcd: ; */
            /* display-run: ; */
            /* display-ssh: ; */
            /* display-drun: ; */
            /* display-combi: ; */
            /* display-keys: ; */
            kb-primary-paste: "Control+V,Shift+Insert";
            kb-secondary-paste: "Control+v,Insert";
            kb-clear-line: "Control+w";
            kb-move-front: "Control+a";
            kb-move-end: "Control+e";
            kb-move-word-back: "Alt+b,Control+Left";
            kb-move-word-forward: "Alt+f,Control+Right";
            kb-move-char-back: "Left,Control+b";
            kb-move-char-forward: "Right,Control+f";
            kb-remove-word-back: "Control+Alt+h,Control+BackSpace";
            kb-remove-word-forward: "Control+Alt+d";
            kb-remove-char-forward: "Delete,Control+d";
            kb-remove-char-back: "BackSpace,Shift+BackSpace,Control+h";
            kb-remove-to-eol: "Control+k";
            kb-remove-to-sol: "Control+u";
            kb-accept-entry: "Control+j,Control+m,Return,KP_Enter";
            kb-accept-custom: "Control+Return";
            kb-accept-alt: "Shift+Return";
            kb-delete-entry: "Shift+Delete";
            kb-mode-next: "Shift+Right,Control+Tab";
            kb-mode-previous: "Shift+Left,Control+ISO_Left_Tab";
            kb-row-left: "Control+Page_Up";
            kb-row-right: "Control+Page_Down";
            kb-row-up: "Up,Control+p,ISO_Left_Tab";
            kb-row-down: "Down,Control+n";
            kb-row-tab: "Tab";
            kb-page-prev: "Page_Up";
            kb-page-next: "Page_Down";
            kb-row-first: "Home,KP_Home";
            kb-row-last: "End,KP_End";
            kb-row-select: "Control+space";
            kb-screenshot: "Alt+S";
            kb-ellipsize: "Alt+period";
            kb-toggle-case-sensitivity: "grave,dead_grave";
            kb-toggle-sort: "Alt+grave";
            kb-cancel: "Escape,Control+g,Control+bracketleft";
            kb-custom-1: "Alt+1";
            kb-custom-2: "Alt+2";
            kb-custom-3: "Alt+3";
            kb-custom-4: "Alt+4";
            kb-custom-5: "Alt+5";
            kb-custom-6: "Alt+6";
            kb-custom-7: "Alt+7";
            kb-custom-8: "Alt+8";
            kb-custom-9: "Alt+9";
            kb-custom-10: "Alt+0";
            kb-custom-11: "Alt+exclam";
            kb-custom-12: "Alt+at";
            kb-custom-13: "Alt+numbersign";
            kb-custom-14: "Alt+dollar";
            kb-custom-15: "Alt+percent";
            kb-custom-16: "Alt+dead_circumflex";
            kb-custom-17: "Alt+ampersand";
            kb-custom-18: "Alt+asterisk";
            kb-custom-19: "Alt+parenleft";
            kb-select-1: "Super+1";
            kb-select-2: "Super+2";
            kb-select-3: "Super+3";
            kb-select-4: "Super+4";
            kb-select-5: "Super+5";
            kb-select-6: "Super+6";
            kb-select-7: "Super+7";
            kb-select-8: "Super+8";
            kb-select-9: "Super+9";
            kb-select-10: "Super+0";
            ml-row-left: "ScrollLeft";
            ml-row-right: "ScrollRight";
            ml-row-up: "ScrollUp";
            ml-row-down: "ScrollDown";
            me-select-entry: "MousePrimary";
            me-accept-entry: "MouseDPrimary";
            me-accept-custom: "Control+MouseDPrimary";
        }

        * {
            font: "Iosevka Term 10";
        }

        #window {
            anchor:     north;
            location:   north;
            width:      100%;
            padding:    3px;
            children:   [ horibox ];
        }

        #horibox {
            orientation: horizontal;
            children:   [ prompt, entry, listview ];
        }

        #listview {
            layout:     horizontal;
            spacing:    5px;
            lines:      100;
        }

        #entry {
            expand:     false;
            width:      10em;
        }

        #element {
            padding: 0px 2px;
        }
        #element selected {
            background-color: SteelBlue;
        }

        * {
            red:                         rgba ( 220, 50, 47, 100 % );
            selected-active-foreground:  rgba ( 253, 246, 227, 100 % );
            lightfg:                     rgba ( 88, 104, 117, 100 % );
            separatorcolor:              var(foreground);
            urgent-foreground:           rgba ( 220, 50, 47, 100 % );
            alternate-urgent-background: var(urgent-background);
            lightbg:                     rgba ( 238, 232, 213, 100 % );
            spacing:                     2;
            border-color:                rgba ( 0, 43, 54, 100 % );
            normal-background:           rgba ( 7, 54, 66, 100 % );
            background-color:            rgba ( 0, 0, 0, 0 % );
            alternate-active-background: var(active-background);
            active-foreground:           rgba ( 38, 139, 210, 100 % );
            blue:                        rgba ( 38, 139, 210, 100 % );
            urgent-background:           rgba ( 7, 54, 66, 100 % );
            alternate-normal-foreground: var(foreground);
            selected-active-background:  rgba ( 38, 139, 210, 100 % );
            background:           rgba ( 7, 54, 66, 100 % );
            selected-normal-foreground:  rgba ( 238, 232, 213, 100 % );
            active-background:           rgba ( 7, 54, 66, 100 % );
            alternate-active-foreground: var(active-foreground);
            alternate-normal-background: var(background);
            foreground:                  rgba ( 131, 148, 150, 100 % );
            selected-urgent-background:  rgba ( 220, 50, 47, 100 % );
            selected-urgent-foreground:  rgba ( 253, 246, 227, 100 % );
            normal-foreground:           var(foreground);
            alternate-urgent-foreground: var(urgent-foreground);
            selected-normal-background:  rgba ( 88, 110, 117, 100 % );
        }
        window {
            background-color: var(background);
        }
        textbox {
            text-color: var(foreground);
        }
        listview {
            scrollbar:    true;
            border-color: var(separatorcolor);
            spacing:      6px ;
            fixed-height: 0;
        }
        element {
            padding: 2px ;
            border:  0;
        }
        element normal.normal {
            background-color: var(normal-background);
            text-color:       var(normal-foreground);
        }
        element normal.urgent {
            background-color: var(urgent-background);
            text-color:       var(urgent-foreground);
        }
        element normal.active {
            background-color: var(active-background);
            text-color:       var(active-foreground);
        }
        element selected.normal {
            background-color: var(selected-normal-background);
            text-color:       var(selected-normal-foreground);
        }
        element selected.urgent {
            background-color: var(selected-urgent-background);
            text-color:       var(selected-urgent-foreground);
        }
        element selected.active {
            background-color: var(selected-active-background);
            text-color:       var(selected-active-foreground);
        }
        element alternate.normal {
            background-color: var(alternate-normal-background);
            text-color:       var(alternate-normal-foreground);
        }
        element alternate.urgent {
            background-color: var(alternate-urgent-background);
            text-color:       var(alternate-urgent-foreground);
        }
        element alternate.active {
            background-color: var(alternate-active-background);
            text-color:       var(alternate-active-foreground);
        }
        scrollbar {
            width:        4px ;
            padding:      0;
            handle-width: 8px ;
            border:       0;
            handle-color: var(normal-foreground);
        }
        mode-switcher {
            border-color: var(separatorcolor);
        }
        button {
            spacing:    0;
            text-color: var(normal-foreground);
        }
        button selected {
            background-color: var(selected-normal-background);
            text-color:       var(selected-normal-foreground);
        }
        inputbar {
            padding:    1px ;
            spacing:    0px ;
            text-color: var(normal-foreground);
            children:   [ prompt,textbox-prompt-colon,entry,overlay,case-indicator ];
        }
        case-indicator {
            spacing:    0;
            text-color: var(normal-foreground);
        }
        entry {
            spacing:    0;
            text-color: var(normal-foreground);
        }
        prompt {
            spacing:    0;
            text-color: var(normal-foreground);
        }
        textbox-prompt-colon {
            margin:     0px 0.3000em 0.0000em 0.0000em ;
            expand:     false;
            str:        ":";
            text-color: inherit;
        }
        error-message {
            background-color: rgba ( 0, 0, 0, 0 % );
            text-color:       var(normal-foreground);
        }
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

        " Don't accidentally :qall
        " https://github.com/tridactyl/tridactyl/issues/350
        alias qall noop

        " Git{Hub,Lab} git clone via SSH yank
        bind yg composite js "git clone " + document.location.href.replace(/https?:\/\//,"git@").replace("/",":").replace(/$/,".git") | clipboard yank

        " Handy multiwindow/multitasking binds
        bind gd tabdetach
        bind gD composite tabduplicate | tabdetach
        bind T composite tabduplicate

        " Stupid workaround to let hint -; be used with composite which steals semi-colons
        command hint_focus hint -;

        " Open right click menu on links
        bind ;C composite hint_focus; !s xdotool key Menu

        " Comment toggler for Reddit and Hacker News
        bind ;c hint -c [class*="expand"],[class="togg"]

        " The default is unintuitive
        bind J tabnext
        bind K tabprev

        " Don't steal my focus
        autocmd TabEnter .* unfocus

        """"""""""""""""""
        " Appearance
        """"""""""""""""""

        " Don’t show modeindicator
        set modeindicator false

        colorscheme zeorin

        """"""""""""""""""
        " Misc settings
        """"""""""""""""""

        " I’m a smooth operator
        set smoothscroll true

        " Sane hinting mode
        set hintfiltermode vimperator-reflow

        " Defaults to 300ms
        set hintdelay 100
      '';
      "tridactyl/themes/zeorin.css".text = ''
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

        !
        ! Solarized color scheme for the X Window System
        !
        ! http://ethanschoonover.com/solarized

        ! Solarized colours

        #define S_yellow        #b58900
        #define S_orange        #cb4b16
        #define S_red           #dc322f
        #define S_magenta       #d33682
        #define S_violet        #6c71c4
        #define S_blue          #268bd2
        #define S_cyan          #2aa198
        #define S_green         #859900
        #define S_base03        #002b36
        #define S_base02        #073642
        #define S_base01        #586e75
        #define S_base00        #657b83
        #define S_base0         #839496
        #define S_base1         #93a1a1
        #define S_base2         #eee8d5
        #define S_base3         #fdf6e3

        ! Common

        st.color0:                  S_base02
        st.color1:                  S_red
        st.color2:                  S_green
        st.color3:                  S_yellow
        st.color4:                  S_blue
        st.color5:                  S_magenta
        st.color6:                  S_cyan
        st.color7:                  S_base2
        st.color8:                  S_base03
        st.color9:                  S_orange
        st.color10:                 S_base01
        st.color11:                 S_base00
        st.color12:                 S_base0
        st.color13:                 S_violet
        st.color14:                 S_base1
        st.color15:                 S_base3

        ! Dark

        st.background:              S_base03
        st.foreground:              S_base0
        st.cursorColor:             S_base1
        st.pointerColorBackground:  S_base01
        st.pointerColorForeground:  S_base1
        st.colorBD:                 S_base3

        ! Light

        ! *background:              S_base3
        ! *foreground:              S_base00
        ! *cursorColor:             S_base01
        ! *pointerColorBackground:  S_base1
        ! *pointerColorForeground:  S_base01
        ! *colorBD:                 S_base03
      '';
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
    ".mozilla/native-messaging-hosts/tridactyl.json".source = "${pkgs.tridactyl-native}/lib/mozilla/native-messaging-hosts/tridactyl.json";
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
      xrdb -load ${configHome}/X11/xresources

      # Polkit agent
      lxqt-policykit-agent &
    '';
  };

  fonts.fontconfig.enable = true;

  nixpkgs.config = {
    allowUnfree = true;
    firefox.enableTridactylNative = true;
  };

  home.packages = with pkgs; [
    (
      let
        configFile = writeText "config.h" ''
          /* See LICENSE file for copyright and license details. */

          /*
          * appearance
          *
          * font: see http://freedesktop.org/software/fontconfig/fontconfig-user.html
          */
          static char *font = "Iosevka:pixelsize=12:antialias=true:autohint=true";
          /* Spare fonts */
          static char *font2[] = {
            "Joypixels:pixelsize=12:antialias=true:autohint=true",
            "Unifont:pixelsize=12:antialias=true:autohint=true",
            "Symbola:pixelsize=12:antialias=true:autohint=true",
          };

          static int borderpx = 12;

          /*
          * What program is execed by st depends of these precedence rules:
          * 1: program passed with -e
          * 2: utmp option
          * 3: SHELL environment variable
          * 4: value of shell in /etc/passwd
          * 5: value of shell in config.h
          */
          static char *shell = "/bin/sh";
          char *utmp = NULL;
          char *stty_args = "stty raw pass8 nl -echo -iexten -cstopb 38400";

          /* identification sequence returned in DA and DECID */
          char *vtiden = "\033[?6c";

          /* Kerning / character bounding-box multipliers */
          static float cwscale = 1.0;
          static float chscale = 1.0;

          /*
          * word delimiter string
          *
          * More advanced example: L" `'\"()[]{}"
          */
          wchar_t *worddelimiters = L" ";

          /* selection timeouts (in milliseconds) */
          static unsigned int doubleclicktimeout = 300;
          static unsigned int tripleclicktimeout = 600;

          /* alt screens */
          int allowaltscreen = 1;

          /* frames per second st should at maximum draw to the screen */
          static unsigned int xfps = 120;
          static unsigned int actionfps = 30;

          /*
          * blinking timeout (set to 0 to disable blinking) for the terminal blinking
          * attribute.
          */
          static unsigned int blinktimeout = 800;

          /*
          * thickness of underline and bar cursors
          */
          static unsigned int cursorthickness = 2;

          /*
          * bell volume. It must be a value between -100 and 100. Use 0 for disabling
          * it
          */
          static int bellvolume = 0;

          /* default TERM value */
          char *termname = "st-256color";

          /*
          * spaces per tab
          *
          * When you are changing this value, don't forget to adapt the »it« value in
          * the st.info and appropriately install the st.info in the environment where
          * you use this st version.
          *
          *	it#$tabspaces,
          *
          * Secondly make sure your kernel is not expanding tabs. When running `stty
          * -a` »tab0« should appear. You can tell the terminal to not expand tabs by
          *  running following command:
          *
          *	stty tabs
          */
          unsigned int tabspaces = 8;

          /* bg opacity */
          float alpha = 1;

          /* Terminal colors (16 first used in escape sequence) */
          static const char *colorname[] = {
            /* 8 normal colors */
            "black",
            "red3",
            "green3",
            "yellow3",
            "blue2",
            "magenta3",
            "cyan3",
            "gray90",

            /* 8 bright colors */
            "gray50",
            "red",
            "green",
            "yellow",
            "#5c5cff",
            "magenta",
            "cyan",
            "white",

            [255] = 0,

            /* more colors can be added after 255 to use with DefaultXX */
            "#cccccc",
            "#555555",
            "black",
            "#2e3440",
          };


          /*
          * Default colors (colorname index)
          * foreground, background, cursor, reverse cursor
          */
          unsigned int defaultfg = 257;
          unsigned int defaultbg = 256;
          static unsigned int defaultcs = 258;
          static unsigned int defaultrcs = 258;

          /* Colors used for selection */
          unsigned int selectionbg = 259;
          unsigned int selectionfg = 256;
          /* If 0 use selectionfg as foreground in order to have a uniform foreground-color */
          /* Else if 1 keep original foreground-color of each cell => more colors :) */
          static int ignoreselfg = 1;

          /*
          * Default shape of cursor
          * 2: Block ("█")
          * 4: Underline ("_")
          * 6: Bar ("|")
          * 7: Snowman ("☃")
          */
          static unsigned int cursorshape = 2;

          /*
          * Default columns and rows numbers
          */

          static unsigned int cols = 80;
          static unsigned int rows = 24;

          /*
          * Default shape of the mouse cursor
          */

          static char* mouseshape = "xterm";

          /*
          * Color used to display font attributes when fontconfig selected a font which
          * doesn't match the ones requested.
          */
          static unsigned int defaultattr = 11;

          /*
          * Force mouse select/shortcuts while mask is active (when MODE_MOUSE is set).
          * Note that if you want to use ShiftMask with selmasks, set this to an other
          * modifier, set to 0 to not use it.
          */
          static uint forcemousemod = ShiftMask;

          /*
          * Xresources preferences to load at startup
          */
          ResourcePref resources[] = {
              { "font",         STRING,  &font },
              { "color0",       STRING,  &colorname[0] },
              { "color1",       STRING,  &colorname[1] },
              { "color2",       STRING,  &colorname[2] },
              { "color3",       STRING,  &colorname[3] },
              { "color4",       STRING,  &colorname[4] },
              { "color5",       STRING,  &colorname[5] },
              { "color6",       STRING,  &colorname[6] },
              { "color7",       STRING,  &colorname[7] },
              { "color8",       STRING,  &colorname[8] },
              { "color9",       STRING,  &colorname[9] },
              { "color10",      STRING,  &colorname[10] },
              { "color11",      STRING,  &colorname[11] },
              { "color12",      STRING,  &colorname[12] },
              { "color13",      STRING,  &colorname[13] },
              { "color14",      STRING,  &colorname[14] },
              { "color15",      STRING,  &colorname[15] },
              { "background",   STRING,  &colorname[256] },
              { "foreground",   STRING,  &colorname[257] },
              { "cursorColor",  STRING,  &colorname[258] },
              { "selection",    STRING,  &colorname[259] },
              { "termname",     STRING,  &termname },
              { "shell",        STRING,  &shell },
              { "xfps",         INTEGER, &xfps },
              { "actionfps",    INTEGER, &actionfps },
              { "blinktimeout", INTEGER, &blinktimeout },
              { "bellvolume",   INTEGER, &bellvolume },
              { "tabspaces",    INTEGER, &tabspaces },
              { "borderpx",     INTEGER, &borderpx },
              { "cwscale",      FLOAT,   &cwscale },
              { "chscale",      FLOAT,   &chscale },
          };

          /*
          * Internal mouse shortcuts.
          * Beware that overloading Button1 will disable the selection.
          */
          static MouseShortcut mshortcuts[] = {
            /* mask                 button   function        argument       release */
            { XK_ANY_MOD,           Button2, selpaste,       {.i = 0},      1 },
            { XK_ANY_MOD,           Button4, ttysend,        {.s = "\031"} },
            { XK_ANY_MOD,           Button5, ttysend,        {.s = "\005"} },
          };

          /* Internal keyboard shortcuts. */
          #define MODKEY Mod1Mask
          #define TERMMOD (ControlMask|ShiftMask)

          static Shortcut shortcuts[] = {
            /* mask                 keysym          function        argument */
            { XK_ANY_MOD,           XK_Break,       sendbreak,      {.i =  0} },
            { ControlMask,          XK_Print,       toggleprinter,  {.i =  0} },
            { ShiftMask,            XK_Print,       printscreen,    {.i =  0} },
            { XK_ANY_MOD,           XK_Print,       printsel,       {.i =  0} },
            { TERMMOD,              XK_Prior,       zoom,           {.f = +1} },
            { TERMMOD,              XK_Next,        zoom,           {.f = -1} },
            { TERMMOD,              XK_Home,        zoomreset,      {.f =  0} },
            { TERMMOD,              XK_C,           clipcopy,       {.i =  0} },
            { TERMMOD,              XK_V,           clippaste,      {.i =  0} },
            { TERMMOD,              XK_Y,           selpaste,       {.i =  0} },
            { ShiftMask,            XK_Insert,      selpaste,       {.i =  0} },
            { TERMMOD,              XK_Num_Lock,    numlock,        {.i =  0} },
          };

          /*
          * Special keys (change & recompile st.info accordingly)
          *
          * Mask value:
          * * Use XK_ANY_MOD to match the key no matter modifiers state
          * * Use XK_NO_MOD to match the key alone (no modifiers)
          * appkey value:
          * * 0: no value
          * * > 0: keypad application mode enabled
          * *   = 2: term.numlock = 1
          * * < 0: keypad application mode disabled
          * appcursor value:
          * * 0: no value
          * * > 0: cursor application mode enabled
          * * < 0: cursor application mode disabled
          *
          * Be careful with the order of the definitions because st searches in
          * this table sequentially, so any XK_ANY_MOD must be in the last
          * position for a key.
          */

          /*
          * If you want keys other than the X11 function keys (0xFD00 - 0xFFFF)
          * to be mapped below, add them to this array.
          */
          static KeySym mappedkeys[] = { -1 };

          /*
          * State bits to ignore when matching key or button events.  By default,
          * numlock (Mod2Mask) and keyboard layout (XK_SWITCH_MOD) are ignored.
          */
          static uint ignoremod = Mod2Mask|XK_SWITCH_MOD;

          /*
          * This is the huge key array which defines all compatibility to the Linux
          * world. Please decide about changes wisely.
          */
          static Key key[] = {
            /* keysym           mask            string      appkey appcursor */
            { XK_KP_Home,       ShiftMask,      "\033[2J",       0,   -1},
            { XK_KP_Home,       ShiftMask,      "\033[1;2H",     0,   +1},
            { XK_KP_Home,       XK_ANY_MOD,     "\033[H",        0,   -1},
            { XK_KP_Home,       XK_ANY_MOD,     "\033[1~",       0,   +1},
            { XK_KP_Up,         XK_ANY_MOD,     "\033Ox",       +1,    0},
            { XK_KP_Up,         XK_ANY_MOD,     "\033[A",        0,   -1},
            { XK_KP_Up,         XK_ANY_MOD,     "\033OA",        0,   +1},
            { XK_KP_Down,       XK_ANY_MOD,     "\033Or",       +1,    0},
            { XK_KP_Down,       XK_ANY_MOD,     "\033[B",        0,   -1},
            { XK_KP_Down,       XK_ANY_MOD,     "\033OB",        0,   +1},
            { XK_KP_Left,       XK_ANY_MOD,     "\033Ot",       +1,    0},
            { XK_KP_Left,       XK_ANY_MOD,     "\033[D",        0,   -1},
            { XK_KP_Left,       XK_ANY_MOD,     "\033OD",        0,   +1},
            { XK_KP_Right,      XK_ANY_MOD,     "\033Ov",       +1,    0},
            { XK_KP_Right,      XK_ANY_MOD,     "\033[C",        0,   -1},
            { XK_KP_Right,      XK_ANY_MOD,     "\033OC",        0,   +1},
            { XK_KP_Prior,      ShiftMask,      "\033[5;2~",     0,    0},
            { XK_KP_Prior,      XK_ANY_MOD,     "\033[5~",       0,    0},
            { XK_KP_Begin,      XK_ANY_MOD,     "\033[E",        0,    0},
            { XK_KP_End,        ControlMask,    "\033[J",       -1,    0},
            { XK_KP_End,        ControlMask,    "\033[1;5F",    +1,    0},
            { XK_KP_End,        ShiftMask,      "\033[K",       -1,    0},
            { XK_KP_End,        ShiftMask,      "\033[1;2F",    +1,    0},
            { XK_KP_End,        XK_ANY_MOD,     "\033[4~",       0,    0},
            { XK_KP_Next,       ShiftMask,      "\033[6;2~",     0,    0},
            { XK_KP_Next,       XK_ANY_MOD,     "\033[6~",       0,    0},
            { XK_KP_Insert,     ShiftMask,      "\033[2;2~",    +1,    0},
            { XK_KP_Insert,     ShiftMask,      "\033[4l",      -1,    0},
            { XK_KP_Insert,     ControlMask,    "\033[L",       -1,    0},
            { XK_KP_Insert,     ControlMask,    "\033[2;5~",    +1,    0},
            { XK_KP_Insert,     XK_ANY_MOD,     "\033[4h",      -1,    0},
            { XK_KP_Insert,     XK_ANY_MOD,     "\033[2~",      +1,    0},
            { XK_KP_Delete,     ControlMask,    "\033[M",       -1,    0},
            { XK_KP_Delete,     ControlMask,    "\033[3;5~",    +1,    0},
            { XK_KP_Delete,     ShiftMask,      "\033[2K",      -1,    0},
            { XK_KP_Delete,     ShiftMask,      "\033[3;2~",    +1,    0},
            { XK_KP_Delete,     XK_ANY_MOD,     "\033[P",       -1,    0},
            { XK_KP_Delete,     XK_ANY_MOD,     "\033[3~",      +1,    0},
            { XK_KP_Multiply,   XK_ANY_MOD,     "\033Oj",       +2,    0},
            { XK_KP_Add,        XK_ANY_MOD,     "\033Ok",       +2,    0},
            { XK_KP_Enter,      XK_ANY_MOD,     "\033OM",       +2,    0},
            { XK_KP_Enter,      XK_ANY_MOD,     "\r",           -1,    0},
            { XK_KP_Subtract,   XK_ANY_MOD,     "\033Om",       +2,    0},
            { XK_KP_Decimal,    XK_ANY_MOD,     "\033On",       +2,    0},
            { XK_KP_Divide,     XK_ANY_MOD,     "\033Oo",       +2,    0},
            { XK_KP_0,          XK_ANY_MOD,     "\033Op",       +2,    0},
            { XK_KP_1,          XK_ANY_MOD,     "\033Oq",       +2,    0},
            { XK_KP_2,          XK_ANY_MOD,     "\033Or",       +2,    0},
            { XK_KP_3,          XK_ANY_MOD,     "\033Os",       +2,    0},
            { XK_KP_4,          XK_ANY_MOD,     "\033Ot",       +2,    0},
            { XK_KP_5,          XK_ANY_MOD,     "\033Ou",       +2,    0},
            { XK_KP_6,          XK_ANY_MOD,     "\033Ov",       +2,    0},
            { XK_KP_7,          XK_ANY_MOD,     "\033Ow",       +2,    0},
            { XK_KP_8,          XK_ANY_MOD,     "\033Ox",       +2,    0},
            { XK_KP_9,          XK_ANY_MOD,     "\033Oy",       +2,    0},
            { XK_Up,            ShiftMask,      "\033[1;2A",     0,    0},
            { XK_Up,            Mod1Mask,       "\033[1;3A",     0,    0},
            { XK_Up,         ShiftMask|Mod1Mask,"\033[1;4A",     0,    0},
            { XK_Up,            ControlMask,    "\033[1;5A",     0,    0},
            { XK_Up,      ShiftMask|ControlMask,"\033[1;6A",     0,    0},
            { XK_Up,       ControlMask|Mod1Mask,"\033[1;7A",     0,    0},
            { XK_Up,ShiftMask|ControlMask|Mod1Mask,"\033[1;8A",  0,    0},
            { XK_Up,            XK_ANY_MOD,     "\033[A",        0,   -1},
            { XK_Up,            XK_ANY_MOD,     "\033OA",        0,   +1},
            { XK_Down,          ShiftMask,      "\033[1;2B",     0,    0},
            { XK_Down,          Mod1Mask,       "\033[1;3B",     0,    0},
            { XK_Down,       ShiftMask|Mod1Mask,"\033[1;4B",     0,    0},
            { XK_Down,          ControlMask,    "\033[1;5B",     0,    0},
            { XK_Down,    ShiftMask|ControlMask,"\033[1;6B",     0,    0},
            { XK_Down,     ControlMask|Mod1Mask,"\033[1;7B",     0,    0},
            { XK_Down,ShiftMask|ControlMask|Mod1Mask,"\033[1;8B",0,    0},
            { XK_Down,          XK_ANY_MOD,     "\033[B",        0,   -1},
            { XK_Down,          XK_ANY_MOD,     "\033OB",        0,   +1},
            { XK_Left,          ShiftMask,      "\033[1;2D",     0,    0},
            { XK_Left,          Mod1Mask,       "\033[1;3D",     0,    0},
            { XK_Left,       ShiftMask|Mod1Mask,"\033[1;4D",     0,    0},
            { XK_Left,          ControlMask,    "\033[1;5D",     0,    0},
            { XK_Left,    ShiftMask|ControlMask,"\033[1;6D",     0,    0},
            { XK_Left,     ControlMask|Mod1Mask,"\033[1;7D",     0,    0},
            { XK_Left,ShiftMask|ControlMask|Mod1Mask,"\033[1;8D",0,    0},
            { XK_Left,          XK_ANY_MOD,     "\033[D",        0,   -1},
            { XK_Left,          XK_ANY_MOD,     "\033OD",        0,   +1},
            { XK_Right,         ShiftMask,      "\033[1;2C",     0,    0},
            { XK_Right,         Mod1Mask,       "\033[1;3C",     0,    0},
            { XK_Right,      ShiftMask|Mod1Mask,"\033[1;4C",     0,    0},
            { XK_Right,         ControlMask,    "\033[1;5C",     0,    0},
            { XK_Right,   ShiftMask|ControlMask,"\033[1;6C",     0,    0},
            { XK_Right,    ControlMask|Mod1Mask,"\033[1;7C",     0,    0},
            { XK_Right,ShiftMask|ControlMask|Mod1Mask,"\033[1;8C",0,   0},
            { XK_Right,         XK_ANY_MOD,     "\033[C",        0,   -1},
            { XK_Right,         XK_ANY_MOD,     "\033OC",        0,   +1},
            { XK_ISO_Left_Tab,  ShiftMask,      "\033[Z",        0,    0},
            { XK_Return,        Mod1Mask,       "\033\r",        0,    0},
            { XK_Return,        XK_ANY_MOD,     "\r",            0,    0},
            { XK_Insert,        ShiftMask,      "\033[4l",      -1,    0},
            { XK_Insert,        ShiftMask,      "\033[2;2~",    +1,    0},
            { XK_Insert,        ControlMask,    "\033[L",       -1,    0},
            { XK_Insert,        ControlMask,    "\033[2;5~",    +1,    0},
            { XK_Insert,        XK_ANY_MOD,     "\033[4h",      -1,    0},
            { XK_Insert,        XK_ANY_MOD,     "\033[2~",      +1,    0},
            { XK_Delete,        ControlMask,    "\033[M",       -1,    0},
            { XK_Delete,        ControlMask,    "\033[3;5~",    +1,    0},
            { XK_Delete,        ShiftMask,      "\033[2K",      -1,    0},
            { XK_Delete,        ShiftMask,      "\033[3;2~",    +1,    0},
            { XK_Delete,        XK_ANY_MOD,     "\033[P",       -1,    0},
            { XK_Delete,        XK_ANY_MOD,     "\033[3~",      +1,    0},
            { XK_BackSpace,     XK_NO_MOD,      "\177",          0,    0},
            { XK_BackSpace,     Mod1Mask,       "\033\177",      0,    0},
            { XK_Home,          ShiftMask,      "\033[2J",       0,   -1},
            { XK_Home,          ShiftMask,      "\033[1;2H",     0,   +1},
            { XK_Home,          XK_ANY_MOD,     "\033[H",        0,   -1},
            { XK_Home,          XK_ANY_MOD,     "\033[1~",       0,   +1},
            { XK_End,           ControlMask,    "\033[J",       -1,    0},
            { XK_End,           ControlMask,    "\033[1;5F",    +1,    0},
            { XK_End,           ShiftMask,      "\033[K",       -1,    0},
            { XK_End,           ShiftMask,      "\033[1;2F",    +1,    0},
            { XK_End,           XK_ANY_MOD,     "\033[4~",       0,    0},
            { XK_Prior,         ControlMask,    "\033[5;5~",     0,    0},
            { XK_Prior,         ShiftMask,      "\033[5;2~",     0,    0},
            { XK_Prior,         XK_ANY_MOD,     "\033[5~",       0,    0},
            { XK_Next,          ControlMask,    "\033[6;5~",     0,    0},
            { XK_Next,          ShiftMask,      "\033[6;2~",     0,    0},
            { XK_Next,          XK_ANY_MOD,     "\033[6~",       0,    0},
            { XK_F1,            XK_NO_MOD,      "\033OP" ,       0,    0},
            { XK_F1, /* F13 */  ShiftMask,      "\033[1;2P",     0,    0},
            { XK_F1, /* F25 */  ControlMask,    "\033[1;5P",     0,    0},
            { XK_F1, /* F37 */  Mod4Mask,       "\033[1;6P",     0,    0},
            { XK_F1, /* F49 */  Mod1Mask,       "\033[1;3P",     0,    0},
            { XK_F1, /* F61 */  Mod3Mask,       "\033[1;4P",     0,    0},
            { XK_F2,            XK_NO_MOD,      "\033OQ" ,       0,    0},
            { XK_F2, /* F14 */  ShiftMask,      "\033[1;2Q",     0,    0},
            { XK_F2, /* F26 */  ControlMask,    "\033[1;5Q",     0,    0},
            { XK_F2, /* F38 */  Mod4Mask,       "\033[1;6Q",     0,    0},
            { XK_F2, /* F50 */  Mod1Mask,       "\033[1;3Q",     0,    0},
            { XK_F2, /* F62 */  Mod3Mask,       "\033[1;4Q",     0,    0},
            { XK_F3,            XK_NO_MOD,      "\033OR" ,       0,    0},
            { XK_F3, /* F15 */  ShiftMask,      "\033[1;2R",     0,    0},
            { XK_F3, /* F27 */  ControlMask,    "\033[1;5R",     0,    0},
            { XK_F3, /* F39 */  Mod4Mask,       "\033[1;6R",     0,    0},
            { XK_F3, /* F51 */  Mod1Mask,       "\033[1;3R",     0,    0},
            { XK_F3, /* F63 */  Mod3Mask,       "\033[1;4R",     0,    0},
            { XK_F4,            XK_NO_MOD,      "\033OS" ,       0,    0},
            { XK_F4, /* F16 */  ShiftMask,      "\033[1;2S",     0,    0},
            { XK_F4, /* F28 */  ControlMask,    "\033[1;5S",     0,    0},
            { XK_F4, /* F40 */  Mod4Mask,       "\033[1;6S",     0,    0},
            { XK_F4, /* F52 */  Mod1Mask,       "\033[1;3S",     0,    0},
            { XK_F5,            XK_NO_MOD,      "\033[15~",      0,    0},
            { XK_F5, /* F17 */  ShiftMask,      "\033[15;2~",    0,    0},
            { XK_F5, /* F29 */  ControlMask,    "\033[15;5~",    0,    0},
            { XK_F5, /* F41 */  Mod4Mask,       "\033[15;6~",    0,    0},
            { XK_F5, /* F53 */  Mod1Mask,       "\033[15;3~",    0,    0},
            { XK_F6,            XK_NO_MOD,      "\033[17~",      0,    0},
            { XK_F6, /* F18 */  ShiftMask,      "\033[17;2~",    0,    0},
            { XK_F6, /* F30 */  ControlMask,    "\033[17;5~",    0,    0},
            { XK_F6, /* F42 */  Mod4Mask,       "\033[17;6~",    0,    0},
            { XK_F6, /* F54 */  Mod1Mask,       "\033[17;3~",    0,    0},
            { XK_F7,            XK_NO_MOD,      "\033[18~",      0,    0},
            { XK_F7, /* F19 */  ShiftMask,      "\033[18;2~",    0,    0},
            { XK_F7, /* F31 */  ControlMask,    "\033[18;5~",    0,    0},
            { XK_F7, /* F43 */  Mod4Mask,       "\033[18;6~",    0,    0},
            { XK_F7, /* F55 */  Mod1Mask,       "\033[18;3~",    0,    0},
            { XK_F8,            XK_NO_MOD,      "\033[19~",      0,    0},
            { XK_F8, /* F20 */  ShiftMask,      "\033[19;2~",    0,    0},
            { XK_F8, /* F32 */  ControlMask,    "\033[19;5~",    0,    0},
            { XK_F8, /* F44 */  Mod4Mask,       "\033[19;6~",    0,    0},
            { XK_F8, /* F56 */  Mod1Mask,       "\033[19;3~",    0,    0},
            { XK_F9,            XK_NO_MOD,      "\033[20~",      0,    0},
            { XK_F9, /* F21 */  ShiftMask,      "\033[20;2~",    0,    0},
            { XK_F9, /* F33 */  ControlMask,    "\033[20;5~",    0,    0},
            { XK_F9, /* F45 */  Mod4Mask,       "\033[20;6~",    0,    0},
            { XK_F9, /* F57 */  Mod1Mask,       "\033[20;3~",    0,    0},
            { XK_F10,           XK_NO_MOD,      "\033[21~",      0,    0},
            { XK_F10, /* F22 */ ShiftMask,      "\033[21;2~",    0,    0},
            { XK_F10, /* F34 */ ControlMask,    "\033[21;5~",    0,    0},
            { XK_F10, /* F46 */ Mod4Mask,       "\033[21;6~",    0,    0},
            { XK_F10, /* F58 */ Mod1Mask,       "\033[21;3~",    0,    0},
            { XK_F11,           XK_NO_MOD,      "\033[23~",      0,    0},
            { XK_F11, /* F23 */ ShiftMask,      "\033[23;2~",    0,    0},
            { XK_F11, /* F35 */ ControlMask,    "\033[23;5~",    0,    0},
            { XK_F11, /* F47 */ Mod4Mask,       "\033[23;6~",    0,    0},
            { XK_F11, /* F59 */ Mod1Mask,       "\033[23;3~",    0,    0},
            { XK_F12,           XK_NO_MOD,      "\033[24~",      0,    0},
            { XK_F12, /* F24 */ ShiftMask,      "\033[24;2~",    0,    0},
            { XK_F12, /* F36 */ ControlMask,    "\033[24;5~",    0,    0},
            { XK_F12, /* F48 */ Mod4Mask,       "\033[24;6~",    0,    0},
            { XK_F12, /* F60 */ Mod1Mask,       "\033[24;3~",    0,    0},
            { XK_F13,           XK_NO_MOD,      "\033[1;2P",     0,    0},
            { XK_F14,           XK_NO_MOD,      "\033[1;2Q",     0,    0},
            { XK_F15,           XK_NO_MOD,      "\033[1;2R",     0,    0},
            { XK_F16,           XK_NO_MOD,      "\033[1;2S",     0,    0},
            { XK_F17,           XK_NO_MOD,      "\033[15;2~",    0,    0},
            { XK_F18,           XK_NO_MOD,      "\033[17;2~",    0,    0},
            { XK_F19,           XK_NO_MOD,      "\033[18;2~",    0,    0},
            { XK_F20,           XK_NO_MOD,      "\033[19;2~",    0,    0},
            { XK_F21,           XK_NO_MOD,      "\033[20;2~",    0,    0},
            { XK_F22,           XK_NO_MOD,      "\033[21;2~",    0,    0},
            { XK_F23,           XK_NO_MOD,      "\033[23;2~",    0,    0},
            { XK_F24,           XK_NO_MOD,      "\033[24;2~",    0,    0},
            { XK_F25,           XK_NO_MOD,      "\033[1;5P",     0,    0},
            { XK_F26,           XK_NO_MOD,      "\033[1;5Q",     0,    0},
            { XK_F27,           XK_NO_MOD,      "\033[1;5R",     0,    0},
            { XK_F28,           XK_NO_MOD,      "\033[1;5S",     0,    0},
            { XK_F29,           XK_NO_MOD,      "\033[15;5~",    0,    0},
            { XK_F30,           XK_NO_MOD,      "\033[17;5~",    0,    0},
            { XK_F31,           XK_NO_MOD,      "\033[18;5~",    0,    0},
            { XK_F32,           XK_NO_MOD,      "\033[19;5~",    0,    0},
            { XK_F33,           XK_NO_MOD,      "\033[20;5~",    0,    0},
            { XK_F34,           XK_NO_MOD,      "\033[21;5~",    0,    0},
            { XK_F35,           XK_NO_MOD,      "\033[23;5~",    0,    0},
          };

          /*
          * Selection types' masks.
          * Use the same masks as usual.
          * Button1Mask is always unset, to make masks match between ButtonPress.
          * ButtonRelease and MotionNotify.
          * If no match is found, regular selection is used.
          */
          static uint selmasks[] = {
            [SEL_RECTANGULAR] = Mod1Mask,
          };

          /*
          * Printable characters in ASCII, used to estimate the advance width
          * of single wide characters.
          */
          static char ascii_printable[] =
            " !\"#$%&'()*+,-./0123456789:;<=>?"
            "@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_"
            "`abcdefghijklmnopqrstuvwxyz{|}~";
        '';
      in ((st.override {
        libXft = xorg.libXft.overrideAttrs (oldAttrs: {
          patches = [
            (fetchurl {
              url =
                https://gitlab.freedesktop.org/xorg/lib/libxft/-/commit/7808631e7a9a605d5fe7a1077129c658d9ec47fc.diff;
              sha256 = "1fkw7ghjfz2svhpc2msz8lyjafzmabgm95xc6dycmb0gb3fq58ik";
            })
          ];
        });
        patches = [ /etc/nixos/st-patches.diff ];
        extraLibs = [ harfbuzz xorg.libXcursor ];
      }).overrideAttrs (oldAttrs: {
        preBuild = "cp ${configFile} config.h";
        src = builtins.fetchGit {
          url = git://git.suckless.org/st;
          ref = "master";
          rev = "5703aa0390484dd7da4bd9c388c85708d8fcd339";
        };
      }))
    )
    webcamoid
    libnotify
    file
    tree
    xsel
    xclip
    xdotool
    curl
    lxqt.lxqt-policykit
    xdg-user-dirs
    wineWowPackages.staging
    (winetricks.override { wine = wineWowPackages.staging; })
    protontricks
    jrnl
    capitaine-cursors
    arc-theme
    arc-icon-theme
    gtk_engines
    gtk-engine-murrine
    wget
    vim
    nodejs
    neovim
    universal-ctags
    dex
    zip
    unzip
    numlockx
    ag
    xorg.xkill
    bc
    rofi
    feh
    lxappearance
    xorg.xcursorthemes
    (polybar.override {
      i3GapsSupport = true;
      mpdSupport = true;
    })
    protonvpn-gui
    protonvpn-cli
    thunderbird
    neomutt
    isync
    brightnessctl
    zathura
    sigil
    (unstable.calibre.overrideAttrs (oldAttrs: {
      buildInputs = oldAttrs.buildInputs ++ (with unstable.python3Packages; [
        pycryptodome
      ]);
    }))
    gnome3.gnome-calculator
    gnome3.file-roller
    youtube-dl
    screenkey
    slop
    system-config-printer
    gnucash
    xournalpp
    transmission-gtk
    mpv
    weechat
    keepassxc
    pcmanfm
    lxmenu-data
    shared_mime_info
    lutris
    vulkan-tools
    gimp
    inkscape
    krita
    libreoffice
    unstable.onlyoffice-bin
    arandr
    barrier
    flameshot
    # TODO this is for the i3-fullscreen screensaver inhibition script, move to its own config later
    (python3.withPackages (python-packages: [ python-packages.i3ipc ]))
    ethtool
    pavucontrol
    ncdu
    playerctl
    qutebrowser
    luakit
    surf
    # (latest.firefox-nightly-bin.override {
    #   browserName = "firefox-nightly";
    #   pname = "firefox-nightly-bin";
    #   desktopName = "Firefox Nightly";
    # })
    # (latest.firefox-beta-bin.override {
    #   browserName = "firefox-beta";
    #   pname = "firefox-beta-bin";
    #   desktopName = "Firefox Beta";
    # })
    # (latest.firefox-esr-bin.override {
    #   browserName = "firefox-esr";
    #   pname = "firefox-esr-bin";
    #   desktopName = "Firefox ESR";
    # })
    ungoogled-chromium
    google-chrome
    google-chrome-beta
    google-chrome-dev
    unstable.tor-browser-bundle-bin
    virt-manager
    qemu
    slack
    discord
    tdesktop
    teams
    skype
    signal-desktop
    spotify
    zoom-us
    unstable.manix
    cachix
    nix-index
    nix-prefetch-git

    # Amphetype
    (with python38Packages; with qt5;
      let
        translitcodec = buildPythonPackage rec {
          pname = "translitcodec";
          version = "0.6.0";
          src = fetchPypi {
            inherit pname version;
            sha256 = "1xh2mqfh3ckl18jqx7sc4bzx8hmg9sxrzhs6vk2x21678xa45j6w";
          };
        };
        editdistance = buildPythonPackage rec {
          pname = "editdistance";
          version = "0.5.3";
          src = fetchPypi {
            inherit pname version;
            sha256 = "07qc2a3igcqaspnj0139zlmn2yssflvl7cqjkv2b4ja6l3fidl49";
          };
        };
      in mkDerivationWith buildPythonPackage rec {
        pname = "amphetype";
        version = "1.0.1";

        src = fetchPypi {
          inherit pname version;
          sha256 = "1sdn0l36r5sxmlkjlly8h6irzhp52krsxpg6m3izqabwpzwc5gp4";
        };

        propagatedBuildInputs = [ pyqt5 qtbase translitcodec editdistance ];

        doCheck = false;

        dontWrapQtApps = true;
        preFixup = ''
          wrapQtApp "$out/bin/amphetype" --prefix PATH : /path/to/bin
        '';
      }
    )

    ((import (fetchFromGitHub {
      owner = "Shopify";
      repo = "comma";
      rev = "1.0.0";
      sha256 = "0n5a3rnv9qnnsrl76kpi6dmaxmwj1mpdd2g0b4n1wfimqfaz6gi1";
    })) { inherit pkgs; })

    # TODO: Remove this once the i3 & polybar configs are managed by
    # home-manager, as we’re only installing it so that we can use `pactl`
    # https://nixos.wiki/wiki/PipeWire#pactl_not_found
    pulseaudio

  ] ++ [

    #########
    # FONTS #
    #########

    # Icon fonts
    emacs-all-the-icons-fonts

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
    gentium
    gentium-book-basic
    crimson
    dejavu_fonts
    overpass
    raleway
    comic-neue
    comic-relief
    fira
    fira-mono
    roboto-mono
    inter
    lato
    libertine
    libertinus
    montserrat
    public-sans
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

    nerdfonts

    # Coding fonts
    # iosevka
    # hack-font
    # go-font
    # hasklig
    # fira-code
    # inconsolata
    # mononoki
    # fantasque-sans-mono

    # Icon fonts
    font-awesome
    material-icons

    # Non-latin character sets
    junicode

    # Fallback fonts
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
  home.stateVersion = "20.03";
}
# vim: set foldmethod=indent foldcolumn=4 shiftwidth=2 tabstop=2 expandtab: