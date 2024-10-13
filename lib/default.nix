{ lib, namespace, ... }:

{
  round = x: if ((x / 2.0) >= 0.5) then (builtins.ceil x) else (builtins.floor x);

  dpiScaleFloat = dpi: x: x * (dpi / 96.0);
  dpiScale = dpi: x: lib.${namespace}.round (lib.${namespace}.dpiScaleFloat dpi x);
}
