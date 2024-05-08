{
  config,
  pkgs,
  ...
}:

let
  emacs = config.programs.emacs.finalPackage;
in
{
  imports = [
    ./vterm.nix
    ./tsc.nix
    ./mu.nix
    ./doom.nix
  ];

  home.sessionVariables = {
    ALTERNATE_EDITOR = "";
    EDITOR = "emacsclient --tty --quiet";
    VISUAL = "emacsclient --create-frame --alternate-editor=emacs --quiet";
  };

  programs.emacs.enable = true;
  programs.emacs.package = pkgs.emacs-pgtk;

  services.emacs = {
    enable = true;
    client.enable = true;
  };

  xdg.configFile = {
    "chemacs/profiles.el".source = pkgs.replaceVars ./chemacs/profiles.el {
      my-emacs = "${config.xdg.configHome}/my-emacs";
      DOOMEMACSDIR = toString pkgs.doomemacs;
      inherit (config.home.sessionVariables) DOOMDIR DOOMLOCALDIR;
    };
    "chemacs/profile".text = "doom";
    emacs.source = pkgs.chemacs2;
  };

  xdg.desktopEntries = {
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
