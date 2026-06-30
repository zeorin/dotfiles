{

  security.soteria.enable = true;
  security.pam.services.swaylock = { };

  programs.niri.enable = true;
  programs.dms-shell.enable = true;

  xdg = {
    autostart.enable = true;
    menus.enable = true;
    mime.enable = true;
    icons.enable = true;
  };
}
