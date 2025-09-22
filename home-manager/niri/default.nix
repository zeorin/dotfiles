{
  pkgs,
  lib,
  dms,
  dgop,
  ...
}:

{
  imports = [ dms.homeModules.dank-material-shell ];

  programs.dank-material-shell = {
    enable = true;
    systemd.enable = true;
    systemd.restartIfChanged = true;
    dgop.package = dgop.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };

  programs.alacritty.enable = true; # Super+T in the default setting (terminal)

  xdg.configFile."niri/config.kdl".source = pkgs.replaceVars ./config.kdl {
    # FIXME: error: attribute 'package' missing
    # dms = lib.getExe config.programs.dank-material-shell.package;
    dms = lib.getExe' dms.packages.${pkgs.stdenv.hostPlatform.system}.dms-shell "dms";
    xdg-terminal-exec = lib.getExe pkgs.xdg-terminal-exec;
    playerctl = lib.getExe pkgs.playerctl;
    wpctl = lib.getExe' pkgs.wireplumber "wpctl";
    brightnessctl = lib.getExe pkgs.brightnessctl;
    DEFAULT_AUDIO_SINK = null;
    DEFAULT_AUDIO_SOURCE = null;
  };

  home.packages = with pkgs; [
    swaybg
    xwayland-satellite
  ];
}
