{
  callPackage,
  mountDir ? null,
}:

let
  tabfs-unwrapped = callPackage ./unwrapped.nix { };
  wrapTabfs = callPackage ./wrapper.nix { };

in
wrapTabfs tabfs-unwrapped { inherit mountDir; }
