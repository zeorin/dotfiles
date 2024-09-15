{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  emacs = config.programs.emacs.finalPackage;
in
{
  imports = [
    ./vterm.nix
    ./tsc.nix
    ./doom.nix
  ];

  home = {
    sessionPath = [ "${config.xdg.configHome}/doom-emacs/bin" ];
    sessionVariables = rec {
      EDITOR = pkgs.writeShellScript "editor" ''
        if [ -n "$INSIDE_EMACS" ]; then
          ${emacs}/bin/emacsclient --quiet "$@"
        else
          ${emacs}/bin/emacsclient --create-frame --alternate-editor="" --quiet "$@"
        fi
      '';
      VISUAL = EDITOR;
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
      SUDO_EDITOR = EDITOR;
    };
  };

  programs.emacs = {
    enable = true;
    package = pkgs.emacs29;
  };

  services.emacs = {
    enable = true;
    client.enable = true;
  };

  xdg.configFile = {
    "chemacs/profiles.el".source = pkgs.unstable.replaceVars ./chemacs/profiles.el {
      my-emacs = "${config.xdg.configHome}/my-emacs";
      doom-emacs = "${config.xdg.configHome}/doom-emacs";
      inherit (config.home.sessionVariables) DOOMDIR DOOMLOCALDIR;
    };
    "chemacs/profile".text = "doom";
    emacs.source = inputs.chemacs;
  };

  xdg.desktopEntries = {
    file-scheme-handler = {
      name = "file:// scheme handler";
      comment = "Open file in editor";
      exec = "${pkgs.writeShellScript "file-scheme-handler" ''
        uri="$1"
        ${pkgs.xdg-utils}/bin/xdg-open "''${1//file:\/\//editor://}"
      ''} %u";
      type = "Application";
      terminal = false;
      categories = [ "System" ];
      mimeType = [ "x-scheme-handler/file" ];
      noDisplay = true;
    };
    editor-scheme-handler = {
      name = "editor:// scheme handler";
      comment = "Open file in editor";
      exec = "${pkgs.writeShellScript "editor-scheme-handler" ''
        ${pkgs.xdg-utils}/bin/xdg-open "''${1//editor:\/\//emacs://}"
      ''} %u";
      type = "Application";
      terminal = false;
      categories = [ "System" ];
      mimeType = [ "x-scheme-handler/editor" ];
      noDisplay = true;
    };
    emacs-scheme-handler = {
      name = "emacs:// scheme handler";
      comment = "Open file in Emacs";
      exec = "${pkgs.writeShellScript "emacs-scheme-handler" ''
        # Unofficial Bash strict mode
        set -euo pipefail

        die() {
          echo "$@" >&2
          exit 1
        }

        declare file
        declare line
        declare column

        # emacs://open?file={path}&line={line}&column={column}
        # emacs://open/?file={path}&line={line}&column={column}
        parseLikeJetbrains() {
          readarray -t parsed < <(echo "$1" |
            awk \
              'match($0, /^emacs:\/\/(open|create|fix)\/?\?file=([^&]+)(&line=([0-9]+)(&column=([0-9]+))?)?$/, a) {
              print a[2]
              print a[4]
              print a[6]
            }')
          file="''${parsed[0]-}"
          line="''${parsed[1]-}"
          column="''${parsed[2]-}"
        }

        # emacs://file/{path}:{line}:{column}
        parseLikeVSCode() {
          readarray -t parsed < <(echo "$1" |
            awk \
              'match($0, /^emacs:\/\/file(\/[^:]+)(:([0-9]+)(:([0-9]+))?)?$/, a) {
              print a[1]
              print a[3]
              print a[5]
            }')
          file="''${parsed[0]-}"
          line="''${parsed[1]-}"
          column="''${parsed[2]-}"
        }

        # emacs:///{path}:{line}:{column}
        # emacs://{host}/{path}:{line}:{column}
        parseLikeFileURL() {
          readarray -t parsed < <(echo "$1" |
            awk \
              'match($0, /^emacs:\/\/([^:]+)(:([0-9]+)(:([0-9]+))?)?$/, a) {
              print a[1]
              print a[3]
              print a[5]
            }')
          file="''${parsed[0]-}"
          line="''${parsed[1]-}"
          column="''${parsed[2]-}"
        }

        parseLikeJetbrains "$1"
        [ -z "$file" ] && parseLikeVSCode "$1"
        [ -z "$file" ] && parseLikeFileURL "$1"
        [ -z "$file" ] && die "Could not parse URI"

        command="emacsclient --no-wait"
        command="$command --eval '(find-file \"$file\")'"
        [ -n "$line" ] && command="$command --eval '(goto-line $line)'"
        [ -n "$column" ] && command="$command --eval '(move-to-column $column)'"
        command="$command --eval '(recenter-top-bottom)'"
        command="$command --eval '(select-frame-set-input-focus (selected-frame))'"
        command="$command --eval '(when (functionp '\"'\"'pulse-momentary-highlight-one-line) (let ((pulse-delay 0.05)) (pulse-momentary-highlight-one-line (point) '\"'\"'highlight)))'"
        eval $command
      ''} %u";
      icon = "emacs";
      type = "Application";
      terminal = false;
      categories = [ "System" ];
      mimeType = [ "x-scheme-handler/emacs" ];
      noDisplay = true;
    };
    org-protocol = {
      name = "org-protocol";
      exec = ''${emacs}/bin/emacsclient --create-frame --alternate-editor="" %u'';
      icon = "emacs";
      type = "Application";
      terminal = false;
      categories = [ "System" ];
      mimeType = [ "x-scheme-handler/org-protocol" ];
      noDisplay = true;
    };
    my-emacs = {
      name = "My Emacs";
      exec = "${emacs}/bin/emacs --with-profile default";
      icon = "emacs";
      type = "Application";
      terminal = false;
      categories = [ "System" ];
    };
  };
}
