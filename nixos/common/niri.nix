{
  nixpkgs-unstable,
  ...
}:

{
  imports = [
    "${nixpkgs-unstable}/nixos/modules/programs/wayland/uwsm.nix"
  ];
  disabledModules = [
    "programs/wayland/uwsm.nix"
  ];

  security.soteria.enable = true;
  security.pam.services.swaylock = { };

  programs.niri.enable = true;

  xdg = {
    autostart.enable = true;
    menus.enable = true;
    mime.enable = true;
    icons.enable = true;
  };
}
