{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:

{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    settings = {
      launch_apps_as_systemd_services = true;

      backdrop = {
        enabled = true;
        blur_intensity = 0.5;
        tint_intensity = 0.3;
      };

      bar.default = {
        auto_hide = true;
        background_opacity = 0.7;
        layer = "overlay";
        reserve_space = false;
      };

      nightlight.enabled = true;

      theme = {
        builtin = "Nord";
        mode = "light";
        source = "builtin";
        templates = {
          builtin_ids = [
            "gtk3"
            "gtk4"
            "kitty"
            "niri"
            "qt"
            "starship"
          ];
          community_ids = [
            "pywalfox-beta4"
            "telegram"
            "gimp"
            "inkscape"
            "libreoffice"
            "rofi"
            "obs"
            "zathura"
            "bat"
          ];
        };
      };

      wallpaper =
        let
          wallpaperDir = ../wallpapers;
        in
        {
          enabled = true;
          fill_mode = "span";
          directory = wallpaperDir;
          directory_dark = "${wallpaperDir}/dark";
          directory_light = "${wallpaperDir}/light";
          default = "${wallpaperDir}/light/martian-terrain.jpg";
          favorite = [
            {
              builtin_palette = "Nord";
              palette_source = "builtin";
              path = "${wallpaperDir}/dark/martian-terrain.jpg";
              theme_mode = "dark";
            }
            {
              builtin_palette = "Nord";
              palette_source = "builtin";
              path = "${wallpaperDir}/light/martian-terrain.jpg";
              theme_mode = "light";
            }
          ];
        };
    };
  };

  services.darkman.scripts = {
    noctalia-theme-mode = ''
      if [ "$1" = "dark" ]; then
        ${lib.getExe config.programs.noctalia.package} msg theme-mode-set dark
      else
        ${lib.getExe config.programs.noctalia.package} msg theme-mode-set light
      fi
    '';
    # TODO: use Noctalia's own hooks to set the wallpaper when the Noctalia theme mode changes
    noctalia-wallpaper = ''
      if [ "$1" = "dark" ]; then
        ${lib.getExe config.programs.noctalia.package} msg wallpaper-set "${config.programs.noctalia.settings.wallpaper.directory_dark}/martian-terrain.jpg"
      else
        ${lib.getExe config.programs.noctalia.package} msg wallpaper-set "${config.programs.noctalia.settings.wallpaper.directory_light}/martian-terrain.jpg"
      fi
    '';
  };

  gtk = {
    enable = true;
    theme.name = "adw-gtk3";
    theme.package = pkgs.adw-gtk3;
    gtk4.theme = config.gtk.theme;
  };

  # home.file.${config.gtk.gtk2.configLocation}.force = true;
  # xdg.configFile."gtk-3.0/settings.ini".force = true;
  xdg.configFile."gtk-4.0/gtk.css".force = true;

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    qt5ctSettings = {
      Appearance = {
        color_scheme_path = "${config.xdg.configHome}/qt5ct/colors/noctalia.conf";
        custom_palette = true;
        standard_dialogs = "xdgdesktopportal";
      };
      # Fonts = {
      #   fixed = "\"DejaVuSansM Nerd Font Mono,12\"";
      #   general = "\"DejaVu Sans,12\"";
      # };
    };
    qt6ctSettings = {
      Appearance = {
        color_scheme_path = "${config.xdg.configHome}/qt6ct/colors/noctalia.conf";
        custom_palette = true;
        standard_dialogs = "xdgdesktopportal";
      };
      # Fonts = {
      #   fixed = "\"DejaVuSansM Nerd Font Mono,12\"";
      #   general = "\"DejaVu Sans,12\"";
      # };
    };
  };
}
