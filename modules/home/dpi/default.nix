{ lib, namespace, ... }@moduleArgs:

{
  options = {
    ${namespace}.dpi = lib.options.mkOption {
      type = lib.types.int;
      default = (moduleArgs.osConfig.${namespace}.dpi or 96);
      example = 192;
    };
  };
}
