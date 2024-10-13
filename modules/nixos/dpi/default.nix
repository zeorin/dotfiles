{ lib, namespace, ... }:

{
  options = {
    ${namespace}.dpi = lib.options.mkOption {
      type = lib.types.int;
      default = 96;
      example = 192;
    };
  };
}
