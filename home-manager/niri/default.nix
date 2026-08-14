{
  pkgs,
  lib,
  config,
  ...
}:

{
  xdg.configFile."niri/config.kdl".source =
    let
      niriConf = pkgs.replaceVars ./config.kdl {
        noctalia = lib.getExe config.programs.noctalia.package;
        darkman = lib.getExe config.services.darkman.package;
        xdg-terminal-exec = lib.getExe pkgs.xdg-terminal-exec;
      };
    in
    pkgs.runCommand "niri-config-checked"
      {
        nativeBuildInputs = [ pkgs.niri ];
      }
      ''
        niri validate --config ${niriConf}
        cp ${niriConf} $out
      '';

  services.swayidle.enable = true;
  services.polkit-gnome.enable = true;

  home.packages = with pkgs; [
    swaybg
    xwayland-satellite
  ];
}
