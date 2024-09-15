{
  config,
  lib,
  pkgs,
  ...
}:

let
  emacs = config.programs.emacs.finalPackage;
in
{
  programs.emacs = {
    extraPackages =
      epkgs: with epkgs; [
        tsc
        treesit-grammars.with-all-grammars
      ];
    extraConfig = ''
      ;; Don't try to download or build the binary, Nix already has it
      (setq tsc-dyn-get-from nil
            tsc-dyn-dir "${emacs.emacs.pkgs.tsc}/share/emacs/site-lisp/elpa/${emacs.emacs.pkgs.tsc.name}")
    '';
  };
}
