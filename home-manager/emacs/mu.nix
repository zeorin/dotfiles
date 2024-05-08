{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.emacs = {
    extraPackages = epkgs: with epkgs; [ mu4e ];
  };
}
