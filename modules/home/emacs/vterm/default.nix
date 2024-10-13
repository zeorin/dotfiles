{
  config,
  lib,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.emacs.vterm;

in
{
  options = {
    ${namespace}.emacs.vterm = {
      enable = lib.options.mkEnableOption "emacs-vterm";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.emacs = {
      extraPackages = epkgs: with epkgs; [ vterm ];
    };

    programs.bash.initExtra = ''
      if [[ "$INSIDE_EMACS" = "vterm" ]] \
         && [[ -n "$EMACS_VTERM_PATH" ]] \
         && [[ -f "$EMACS_VTERM_PATH/etc/emacs-vterm-bash.sh" ]]; then
        source "$EMACS_VTERM_PATH/etc/emacs-vterm-bash.sh"
      fi
    '';

    programs.zsh.initExtra = ''
      if [[ "$INSIDE_EMACS" = "vterm" ]] \
         && [[ -n "$EMACS_VTERM_PATH" ]] \
         && [[ -f "$EMACS_VTERM_PATH/etc/emacs-vterm-zsh.sh" ]]; then
        source "$EMACS_VTERM_PATH/etc/emacs-vterm-zsh.sh"
      fi
    '';

    programs.fish.interactiveShellInit = ''
      if [ "$INSIDE_EMACS" = "vterm" ] \
         && [ -n "$EMACS_VTERM_PATH" ] \
         && [ -f "$EMACS_VTERM_PATH/etc/emacs-vterm.fish" ]
        source "$EMACS_VTERM_PATH/etc/emacs-vterm.fish"
      end
    '';
  };
}
