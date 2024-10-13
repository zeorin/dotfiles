{
  config,
  lib,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.emacs.tsc;
  emacs = config.programs.emacs.finalPackage;
in
{
  options.${namespace}.emacs.tsc = {
    enable = lib.options.mkEnableOption "tsc";
  };

  config = lib.mkIf cfg.enable {
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
  };
}
