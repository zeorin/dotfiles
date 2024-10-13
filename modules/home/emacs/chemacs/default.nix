{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:

let
  emacsCfg = config.${namespace}.emacs;
  emacs = emacsCfg.package;
  cfg = emacsCfg.chemacs;

in
{
  options.${namespace}.emacs.chemacs = {
    enable = lib.options.mkEnableOption "chemacs";

    package = lib.options.mkPackageOption pkgs "chemacs2" { };

    wrapped = lib.options.mkOption {
      type = lib.types.package;
      visible = false;
      readOnly = true;
      description = ''
        The Emacs package wrapped to use Chemacs as its init directory;
      '';
    };

    profiles = lib.options.mkOption {
      default = {
        default = {
          user-emacs-directory = "${config.xdg.configHome}/emacs";
        };
      };
      description = "Whether to make DOOM Emacs the default Chemacs profile.";
      type = lib.types.attrsOf lib.types.attrs;
    };

    default = lib.options.mkOption {
      default = null;
      example = "default";
      description = "Which profile Chemacs should load by default";
      type = lib.types.nullOr lib.types.string;
    };
  };

  config = lib.mkIf cfg.enable {
    "${namespace}".emacs.chemacs.wrapped = (
      pkgs.symlinkJoin {
        inherit (emacs) name;
        paths = [ emacs ];
        nativeBuildInputs = with pkgs; [ makeWrapper ];
        postBuild = ''
          for prog in $out/bin/*; do
            wrapProgram $out/bin/$prog \
              --add-flags "--init-directory \"${cfg.package}/share/site-lisp/chemacs2\""
          done
        '';
      }
    );

    xdg.configFile = {
      "chemacs/profiles.el".text = lib.mkIf (cfg.profiles != { }) "(${
        lib.generators.toKeyValue {
          mkKeyValue =
            profile: settings:
            "(\"${profile}\" . (${
              lib.generators.toKeyValue {
                mkKeyValue =
                  let
                    mkValueString =
                      v:
                      if lib.isInt v then
                        lib.toString v
                      else if lib.isString v then
                        "\"${v}\""
                      else if true == v then
                        "t"
                      else if false == v then
                        "nil"
                      else
                        lib.err "this value is" (lib.toString v);
                  in
                  k: v: "(${k} . ${mkValueString v})\n";
              } settings
            })";
        }
      })" cfg.profiles;
      "chemacs/profile".text = lib.mkIf (cfg.default != null) cfg.default;
    };
  };
}
