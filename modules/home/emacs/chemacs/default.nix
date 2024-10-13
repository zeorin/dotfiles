{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.emacs.chemacs;

in
{
  options = {
    ${namespace}.emacs.chemacs = {
      enable = lib.options.mkEnableOption "chemacs";

      package = lib.options.mkPackageOption pkgs "chemacs2" { };

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
        type = lib.types.nullOr lib.types.str;
      };
    };
  };

  config = lib.mkIf cfg.enable {

    ${namespace}.emacs.init-directory = "${cfg.package}/share/site-lisp/chemacs2";

    xdg.configFile = {
      "chemacs/profiles.el".text =
        lib.mkIf (cfg.profiles != { })
          "(${
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
                }))";
            } cfg.profiles
          })";
      "chemacs/profile".text = lib.mkIf (cfg.default != null) cfg.default;
    };
  };
}
