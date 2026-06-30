{
  pkgs,
  lib,
  osConfig,
  ...
}:

{
  xdg.configFile."niri/config.kdl".source = pkgs.replaceVars ./config.kdl {
    dms = lib.getExe' osConfig.programs.dms-shell.package "dms";
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
