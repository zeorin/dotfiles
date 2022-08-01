{ pkgs, config, lib, ... }:

let
  unstable = import <nixos-unstable> {
    config = config.nixpkgs.config;
    overlays = [
      (import (builtins.fetchTarball {
        url =
          "https://github.com/nix-community/emacs-overlay/archive/master@{1%20day%20ago}.tar.gz";
      }))
    ];
  };
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
  st = let
    config = pkgs.writeText "config.h" ''
      /* See LICENSE file for copyright and license details. */

      /*
      * appearance
      *
      * font: see http://freedesktop.org/software/fontconfig/fontconfig-user.html
      */
      static char *font = "Iosevka Term:pixelsize=14:antialias=true:autohint=true";
      /* Spare fonts */
      static char *font2[] = {
        "Joypixels:pixelsize=14:antialias=true:autohint=true",
        "Unifont:pixelsize=14:antialias=true:autohint=true",
        "Symbola:pixelsize=14:antialias=true:autohint=true",
      };

      static int borderpx = 14;

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
        "${colors.nord0}",
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
      unsigned int selectionbg = 3;
      unsigned int selectionfg = 0;
      /* If 0 use selectionfg as foreground in order to have a uniform foreground-color */
      /* Else if 1 keep original foreground-color of each cell => more colors : */
      static int ignoreselfg = 0;

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
  in ((pkgs.st.override {
    patches = [ /etc/nixos/st-patches.diff ];
    extraLibs = with pkgs; [ harfbuzz xorg.libXcursor ];
  }).overrideAttrs (oldAttrs: {
    preBuild = "cp ${config} config.h";
    src = builtins.fetchGit {
      url = "git://git.suckless.org/st";
      ref = "master";
      rev = "5703aa0390484dd7da4bd9c388c85708d8fcd339";
    };
  }));
  terminal-emulator = "${st}/bin/st";
in {
  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url = "https://github.com/mozilla/nixpkgs-mozilla/archive/master.tar.gz";
    }))
  ];

  imports = [
    "${
      fetchTarball
      "https://github.com/msteen/nixos-vscode-server/tarball/master"
    }/modules/vscode-server/home.nix"
  ];

  programs.home-manager.enable = true;
  programs.man.generateCaches = true;

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
    sessionVariables = with config.xdg; rec {
      EDITOR = "nvim";
      VISUAL = "${EDITOR}";
      LESS = "-FiRx4";
      PAGER = "less ${LESS}";
      PASSWORD_STORE_GENERATED_LENGTH = 128;

      # Help some tools actually adhere to XDG Base Dirs
      CURL_HOME = "${configHome}/curl";
      INPUTRC = "${configHome}/readline/inputrc";
      NPM_CONFIG_USERCONFIG = "${configHome}/npm/npmrc";
      WEECHAT_HOME = "${configHome}/weechat";
      WGETRC = "${configHome}/wget/wgetrc";
      LESSHISTFILE = "${cacheHome}/less/history";
      PSQL_HISTORY = "${cacheHome}/pg/psql_history";
      XCOMPOSECACHE = "${cacheHome}/X11/xcompose";
      GOPATH = "${dataHome}/go";
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
  };

  programs = {
    bash.enable = true;
    browserpass = {
      enable = true;
      browsers = [ "firefox" "chromium" "chrome" ];
    };
    dircolors = {
      enable = true;
      extraConfig = builtins.readFile "${
          pkgs.fetchFromGitHub {
            owner = "arcticicestudio";
            repo = "nord-dircolors";
            rev = "v0.2.0";
            sha256 = "1c9fa6dip266z6hfqd5nan5v6qjp6dg074lvk4rxisirm26djlzz";
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
    emacs = {
      enable = true;
      package = let emacsPkg = unstable.emacsPgtkNativeComp;
      in with pkgs;
      symlinkJoin (lib.recursiveUpdate {
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
            --prefix PATH : "${nodePackages.typescript-language-server}/bin" \
            --prefix PATH : "${nodePackages.vscode-css-languageserver-bin}/bin" \
            --prefix PATH : "${nodePackages.vscode-html-languageserver-bin}/bin" \
            --prefix PATH : "${nodePackages.prettier}/bin" \
            --prefix PATH : "${nixfmt}/bin" \
            --prefix PATH : "${sqlite}/bin" \
            --prefix PATH : "${editorconfig-core-c}/bin" \
            --prefix PATH : "${nodePackages.mermaid-cli}/bin" \
            --prefix PATH : "${pandoc}/bin" \
            --prefix PATH : "${gcc}/bin"
        '';
      } (lib.recursiveUpdate { inherit (emacsPkg) meta src; } {
        meta.platforms = lib.platforms.linux;
      }));
      extraPackages = epkgs: (with epkgs; [ vterm ]);
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
          bypass-paywalls-clean
          canvasblocker
          clearurls
          cookies-txt
          darkreader
          mailvelope
          metamask
          netflix-1080p
          octolinker
          octotree
          org-capture
          privacy-badger
          react-devtools
          reddit-enhancement-suite
          reduxdevtools
          refined-github
          tab-session-manager
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
            firefox-csshacks = pkgs.fetchFromGitHub {
              owner = "MrOtherGuy";
              repo = "firefox-csshacks";
              rev = "753c37d010836fc53dbab9d005663d52fe4f7930";
              sha256 = "02wzb6l4vi04va41h76wiji3xq7ma6bs2ybbc5sp5lhsnqizis16";
            };
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
        l = "ls -lFh"; # size,show type,human readable
        la = "ls -lAFh"; # long list,show almost all,show type,human readable
        lr = "ls -tRFh"; # sorted by date,recursive,show type,human readable
        lt = "ls -ltFh"; # long list,sorted by date,show type,human readable
        ll = "ls -l"; # long list
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
          source ${unstable.emacsPackages.vterm}/share/emacs/site-lisp/elpa/vterm-${unstable.emacsPackages.vterm.version}/etc/emacs-vterm.fish
        end
      '';
      # source ${config.programs.emacs.package.pkgs.vterm}/share/emacs/site-lisp/elpa/vterm-${config.programs.emacs.package.pkgs.vterm.version}/etc/emacs-vterm.fish
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
        init.defaultBranch = "main";
        credential.helper = "${pkgs.pass-git-helper}/bin/pass-git-helper";
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
          path = "~/Code/WyzeTalk/.gitconfig";
          condition = "gitdir:~/Code/WyzeTalk/";
        }
        {
          path = "~/Code/NectaTech/.gitconfig";
          condition = "gitdir:~/Code/NectaTech/";
        }
      ];
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
    gpg = {
      enable = true;
      homedir = "${config.xdg.dataHome}/gnupg";
      settings = { keyserver = "hkps://keys.openpgp.org/"; };
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
        name = "Iosevka Term";
        size = 10;
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
          pass-otp
          pass-import
          pass-audit
          pass-update
          pass-checkup
          pass-genphrase
          pass-tomb
        ]);
    };
    rofi = {
      enable = true;
      pass.enable = true;
      font = "Iosevka Term 12";
      location = "center";
      terminal = terminal-emulator;
      yoffset = -280;
      extraConfig = { show-icons = true; };
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
    starship.enable = true;
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
    vscode = {
      enable = true;
      package = unstable.vscode-fhsWithPackages (ps: with ps; [ python3 ]);
      extensions =
        (with unstable.vscode-extensions; [ bbenoist.nix vscodevim.vim ])
        ++ unstable.vscode-utils.extensionsFromVscodeMarketplace [{
          name = "direnv";
          publisher = "mkhl";
          version = "0.6.1";
          sha256 = "5/Tqpn/7byl+z2ATflgKV1+rhdqj+XMEZNbGwDmGwLQ=";
        }];
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
          font = "Iosevka Term 10";
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
        urgency_low = { background = "${colors.nord3}cc"; };
        urgency_normal = { background = "${colors.nord10}cc"; };
        urgency_critical = {
          background = "${colors.nord11}cc";
          fullscreen = "show";
          timeout = 0;
        };
      };
    };
    emacs = {
      enable = true;
      client.enable = true;
    };
    flameshot.enable = true;
    gpg-agent.enable = true;
    network-manager-applet.enable = true;
    nextcloud-client.enable = true;
    picom = {
      enable = true;
      package = let picomPkg = pkgs.picom;
      in with pkgs;
      symlinkJoin (lib.recursiveUpdate {
        name = "picom";
        paths = [ picomPkg ];
        buildInputs = [ makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/picom \
            --add-flags \''${ARG_0:+\"\$ARG_0\"} \
            --add-flags \''${ARG_1:+\"\$ARG_1\"}
        '';
      } { inherit (picomPkg) meta src; });
      fade = true;
      fadeDelta = 3;
      inactiveDim = "0.2";
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
        "_GTK_FRAME_EXTENTS@:c"
        # notifications
        "_NET_WM_WINDOW_TYPE@:32a *= '_NET_WM_WINDOW_TYPE_NOTIFICATION'"
        # Mozilla fixes
        "(class_g = 'Firefox' || class_g = 'Thunderbird') && (window_type = 'utility' || window_type = 'popup_menu') && argb"
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
        xrender-sync-fence = true;
        focus-exclude = [
          "name = 'Picture-in-Picture'",
          "_NET_WM_STATE@:32a *= '_NET_WM_STATE_FULLSCREEN'"
        ];
      '';
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
          # modules-center = "mpd";
          modules-right = "pipewire-simple xkeyboard battery date";

          tray-position = "right";
          tray-padding = 2;
          tray-maxsize = 32;
          tray-foreground = colors.nord4;
          tray-background = colors.background;
          tray-prefix = "";
          tray-prefix-font = 4;
          tray-prefix-foreground = colors.nord3;
          tray-prefix-background = colors.nord0;

          scroll-up = "i3wm-wsnext";
          scroll-down = "i3wm-wsprev";

          font-0 = "Iosevka Nerd Font:size=10;3";
          font-1 = "Iosevka Nerd Font:size=10;3";
          font-2 = "Iosevka Nerd Font:size=8;3";
          font-3 = "Iosevka Nerd Font:size=16;4";
          font-4 = "Iosevka Nerd Font:size=20;0";
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
          format-suffix-font = 4;
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
          label-unfocused-foreground = "\${self.format-foreground}";
          label-unfocused-background = "\${self.format-background}";
          label-unfocused-padding = 1;

          # focused = Active workspace on focused monitor
          label-focused = "%name%";
          label-focused-foreground = colors.nord6;
          label-focused-background = "\${self.format-background}";
          label-focused-padding = 1;

          # visible = Active workspace on unfocused monitor
          label-visible = "%name%";
          label-visible-foreground = colors.nord10;
          label-visible-background = "\${self.format-background}";
          label-visible-padding = 1;

          # urgent = Workspace with urgency hint set
          label-urgent = "%name%";
          label-urgent-foreground = colors.nord13;
          label-urgent-background = "\${self.format-background}";
          label-urgent-padding = 1;
        };
        "module/title" = {
          type = "internal/xwindow";
          format-background = colors.nord1;
          format-suffix = "";
          format-suffix-font = 4;
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
        };
        "module/battery" = {
          type = "internal/battery";
          battery = "BAT0";
          adapter = "ADP1";
          full-at = "98";

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
          label-font = 2;
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

        # Lock screen
        "super + x" = "${pkgs.systemd}/bin/loginctl lock-session";

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
    initExtra = let backgroundImage = ../backgrounds/hidden-valley.jpg;
    in "${pkgs.feh}/bin/feh --no-fehbg --no-xinerama --bg-fill ${backgroundImage} &";
    windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;
      config = let
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
            # Define workspace names
            "${mod}+1" = "workspace 1: ";
            "${mod}+2" = "workspace 2: ";
            "${mod}+3" = "workspace 3: ";
            "${mod}+4" = "workspace 4: ";
            "${mod}+5" = "workspace 5: ";
            "${mod}+6" = "workspace 6: 6";
            "${mod}+7" = "workspace 7: 7";
            "${mod}+8" = "workspace 8: ";
            "${mod}+9" = "workspace 9: ";
            "${mod}+0" = "workspace 10: ";
            # move focused container to workspace
            "${mod}+Shift+1" =
              "move container to workspace number 1; workspace number 1";
            "${mod}+Shift+2" =
              "move container to workspace number 2; workspace number 2";
            "${mod}+Shift+3" =
              "move container to workspace number 3; workspace number 3";
            "${mod}+Shift+4" =
              "move container to workspace number 4; workspace number 4";
            "${mod}+Shift+5" =
              "move container to workspace number 5; workspace number 5";
            "${mod}+Shift+6" =
              "move container to workspace number 6; workspace number 6";
            "${mod}+Shift+7" =
              "move container to workspace number 7; workspace number 7";
            "${mod}+Shift+8" =
              "move container to workspace number 8; workspace number 8";
            "${mod}+Shift+9" =
              "move container to workspace number 9; workspace number 9";
            "${mod}+Shift+0" =
              "move container to workspace number 10; workspace number 10";

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
            "plus" = "gaps inner current plus 6";
            "minus" = "gaps inner current minus 6";
            "asterisk" = "gaps inner current set 0";
            "Shift+plus" = "gaps inner all plus 6";
            "Shift+minus" = "gaps inner all minus 6";
            "Shift+asterisk" = "gaps inner all set 0";
            "Return" = "mode default";
            "Escape" = "mode default";
          };
          "${mode-gaps-outer}" = {
            "plus" = "gaps outer current plus 6";
            "minus" = "gaps outer current minus 6";
            "asterisk" = "gaps outer current set 0";
            "Shift+plus" = "gaps outer all plus 6";
            "Shift+minus" = "gaps outer all minus 6";
            "Shift+asterisk" = "gaps outer all set 0";
            "Return" = "mode default";
            "Escape" = "mode default";
          };
        };
        assigns = {
          "number 2" = [{
            class = "^Firefox$";
            window_role = "(?i)^((?!dialog).)+$";
          }];
          "number 9" = [{ class = "^Thunderbird$"; }];
          "number 10" = [
            { class = "^TelegramDesktop$"; }
            { class = "^Slack$"; }
            { class = "^Skype$"; }
            { class = "^Signal$"; }
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
          (mkFloating { class = "^Tor Browser$"; })
          (mkFloating { class = "^gnome-calculator$"; })
          (mkFloating { class = "^feh$"; })
          (mkFloating { class = "^Sxiv$"; })
          (mkFloating {
            class = "^Thunderbird$";
            instance = "^Calendar$";
          })
          (mkFloating { class = "^(?i)zoom$"; })
          (mkFloating { class = "(?i)blueman-manager"; })
          (mkFloating { window_type = "dialog"; })
          (mkFloating { window_role = "pop-up"; })
          (mkFloating { window_role = "(?i)about"; })
          (mkFloating { window_role = "(?i)preferences"; })
          (mkSticky { title = "Picture-in-Picture"; })
          (mkSticky { title = "AlarmWindow"; })
        ];
      };
    };
  };

  systemd.user = {
    services = {
      batsignal = {
        Unit.Description = "Battery monitor daemon";
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.batsignal}/bin/batsignal";
          Restart = "on-failure";
          RestartSec = 1;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
      # Allow for bluetooth devices to interface with MPRIS
      mpris-proxy = {
        Unit = {
          Description = "Forward bluetooth media controls to MPRIS";
          After = [ "network.target" "sound.target" ];
        };
        Service.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
        Install.WantedBy = [ "default.target" ];
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
    };
  };

  xdg = {
    enable = true;
    userDirs.enable = true;
    configFile = with config.xdg; {
      "mimeapps.list".force = true; # Force overwrite, don't prompt
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
        source = builtins.fetchGit "https://github.com/hlissner/doom-emacs";
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
        (setq doom-font (font-spec :family "Iosevka Term" :size 12 :weight 'light)
              doom-variable-pitch-font (font-spec :family "Iosevka Aile" :size 13)
              doom-big-font (font-spec :family "Iosevka Term" :size 24 :weight 'light))

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
                 fill-column       ; a `fill-column' indicator
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
                 syntax              ; tasing you for every semicolon you forget
                 (spell +flyspell) ; tasing you for misspelling mispelling
                 grammar           ; tasing grammar mistake every you make

                 :tools
                 ;;ansible
                 ;;debugger          ; FIXME stepping through code, to help you add bugs
                 direnv
                 ;;docker
                 editorconfig      ; let someone else argue about tabs vs spaces
                 ;;ein               ; tame Jupyter notebooks with emacs
                 (eval +overlay)     ; run code, run (also, repls)
                 ;;gist              ; interacting with github gists
                 lookup              ; navigate your code and its documentation
                 lsp
                 magit             ; a git porcelain for Emacs
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
                 ;;cc                ; C/C++/Obj-C madness
                 ;;clojure           ; java with a lisp
                 ;;common-lisp       ; if you've seen one lisp, you've seen them all
                 ;;coq               ; proofs-as-programs
                 ;;crystal           ; ruby at the speed of c
                 ;;csharp            ; unity, .NET, and mono shenanigans
                 ;;data              ; config/data formats
                 (dart +flutter)   ; paint ui and not much else
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
                 (haskell +dante)  ; a language that's lazier than I am
                 ;;hy                ; readability of scheme w/ speed of python
                 ;;idris             ; a language you can depend on
                 json              ; At least it ain't XML
                 ;;(java +meghanada) ; the poster child for carpal tunnel syndrome
                 (javascript +lsp)        ; all(hope(abandon(ye(who(enter(here))))))
                 ;;julia             ; a better, faster MATLAB
                 ;;kotlin            ; a better, slicker Java(Script)
                 ;;latex             ; writing papers in Emacs has never been so fun
                 ;;lean
                 ;;factor
                 ;;ledger            ; an accounting system in Emacs
                 ;;lua               ; one-based indices? one-based indices
                 markdown          ; writing docs for people to ignore
                 ;;nim               ; python + lisp at the speed of c
                 nix               ; I hereby declare "nix geht mehr!"
                 ;;ocaml             ; an objective camel
                 (org               ; organize your plain life in plain text
                  +pretty
                  +roam2)
                 ;;php               ; perl's insecure younger brother
                 ;;plantuml          ; diagrams for confusing people more
                 ;;purescript        ; javascript, but functional
                 ;;python            ; beautiful is better than ugly
                 ;;qt                ; the 'cutest' gui framework ever
                 ;;racket            ; a DSL for DSLs
                 ;;raku              ; the artist formerly known as perl6
                 ;;rest              ; Emacs as a REST client
                 ;;rst               ; ReST in peace
                 ;;(ruby +rails)     ; 1.step {|i| p "Ruby is #{i.even? ? 'love' : 'life'}"}
                 ;;rust              ; Fe2O3.unwrap().unwrap().unwrap().unwrap()
                 ;;scala             ; java, but good
                 ;;scheme            ; a fully conniving family of lisps
                 sh                ; she sells {ba,z,fi}sh shells on the C xor
                 ;;sml
                 ;;solidity          ; do you need a blockchain? No.
                 ;;swift             ; who asked for emoji variables?
                 ;;terra             ; Earth and Moon in alignment for performance.
                 (web +lsp)              ; the tubes
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
        '';
        onChange = "${pkgs.writeShellScript "doom-config-packages-change" ''
          export DOOMDIR="${config.home.sessionVariables.DOOMDIR}"
          export DOOMLOCALDIR="${config.home.sessionVariables.DOOMLOCALDIR}"
          ${configHome}/doom-emacs/bin/doom --force sync
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
        tmp=$XDG_RUNTIME_DIR/npm
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

        " Comment toggler for Reddit, Hacker News and Lobste.rs
        bind ;c hint -Jc [class*="expand"],[class="togg"],[class="comment_folder"]

        " The default is unintuitive
        bind J tabnext
        bind K tabprev

        " Don't steal my focus
        autocmd TabEnter .* unfocus
        autocmd DocLoad .* unfocus

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

        colorscheme zeorin

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
        autocmd TabEnter .* unfocus
        autocmd DocLoad .* unfocus
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
      "applications/mimeapps.list".force = true; # Force overwrite, don't prompt
      "dark-mode.d/gtk-theme.sh".source =
        pkgs.writeShellScript "set-dark-theme.sh" ''
          ${pkgs.xfce.xfconf}/bin/xfconf-query --create --type string -c xsettings -p /Net/ThemeName -s "Nordic"
          ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
        '';
      "light-mode.d/gtk-theme.sh".source =
        pkgs.writeShellScript "set-light-theme.sh" ''
          ${pkgs.xfce.xfconf}/bin/xfconf-query --create --type string -c xsettings -p /Net/ThemeName -s "Nordic-Polar"
          ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'prefer-light'"
        '';
    };
    desktopEntries = {
      org-protocol = {
        name = "org-protocol";
        exec = "emacsclient %u";
        icon = "emacs";
        type = "Application";
        terminal = false;
        categories = [ "System" ];
        mimeType = [ "x-scheme-handler/org-protocol" ];
      };
    };
    mimeApps = {
      enable = true;
      defaultApplications = {
        "application/pdf" = [ "org.pwmt.zathura-pdf-mupdf.desktop" ];
        "application/xhtml+xml" = [ "firefox.desktop" ];
        "inode/directory" = [ "pcmanfm.desktop" ];
        "text/html" = [ "firefox.desktop" ];
        "text/xml" = [ "firefox.desktop" ];
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
        "x-scheme-handler/org-protocol" = [ "org-protocol.desktop" ];
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
      xrdb -load ${configHome}/X11/xresources

      # Polkit agent
      lxqt-policykit-agent &
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
      webcamoid
      libnotify
      file
      tree
      xsel
      xclip
      curl
      httpie
      lxqt.lxqt-policykit
      xdg-user-dirs
      wineWowPackages.stable
      winetricks
      protontricks
      jrnl
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
      nodejs
      neovim
      universal-ctags
      zip
      unzip
      numlockx
      filezilla
      silver-searcher
      ripgrep
      xorg.xkill
      bc
      feh
      lxappearance
      xorg.xcursorthemes
      protonvpn-gui
      # protonvpn-cli
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
      unstable.yt-dlp
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
      shared-mime-info
      unstable.lutris
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
      # TODO this is for the i3-fullscreen screensaver inhibition script, move to its own config later
      (python3.withPackages (python-packages: [ python-packages.i3ipc ]))
      ethtool
      pavucontrol
      ncdu
      qutebrowser
      luakit
      surf
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
      unstable.tor-browser-bundle-bin
      virt-manager
      qemu
      unstable.slack
      unstable.discord
      unstable.tdesktop
      unstable.skypeforlinux
      unstable.signal-desktop
      (symlinkJoin {
        name = "zoom-us";
        paths = [ unstable.zoom-us ];
        buildInputs = [ makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/zoom \
            --set QT_AUTO_SCREEN_SCALE_FACTOR 0 \
            --set QT_SCALE_FACTOR 2
        '';
      })
      unstable.element-desktop
      (symlinkJoin {
        name = "spotify";
        paths = [ spotify ];
        buildInputs = [ makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/spotify \
            --add-flags "--force-device-scale-factor=2"
        '';
      })
      unstable.minecraft
      manix
      cachix
      nix-prefetch-git
      nix-prefetch
      keybase
      unstable.comma
      zeal

      # For dark mode toggling
      xfce.xfconf

      retroarchFull
      mangohud
      protonup

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

      (nerdfonts.override { fonts = [ "Iosevka" ]; })
      (iosevka-bin.override { variant = "aile"; })
      (iosevka-bin.override { variant = "etoile"; })

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
