{
  pkgs,
  ...
}:

{
  programs.emacs = {
    overrides = (
      final: prev: {
        inherit (pkgs.unstable.emacsPackages) ghostel evil-ghostel;
      }
    );
    extraPackages =
      epkgs: with epkgs; [
        ghostel
        evil-ghostel
      ];
  };

  programs.bash.initExtra = ''
    [[ "''${INSIDE_EMACS%%,*}" = 'ghostel' ]] && source "$EMACS_GHOSTEL_PATH/etc/shell/ghostel.bash"
  '';

  programs.zsh.initExtra = ''
    [[ "''${''${INSIDE_EMACS-}%%,*}" = 'ghostel' ]] && source "$EMACS_GHOSTEL_PATH/etc/shell/ghostel.zsh"
  '';

  programs.fish.interactiveShellInit = ''
    string match -qr '^ghostel(,|$)' -- "$INSIDE_EMACS"; and source "$EMACS_GHOSTEL_PATH/etc/shell/ghostel.fish"
  '';
}
