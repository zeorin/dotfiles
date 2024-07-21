# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{
  pkgs ? (import ../nixpkgs.nix) { },
}:

with pkgs;

{
  wrapTabfs = callPackage ./tabfs/wrapper.nix { };
  tabfs-unwrapped = callPackage ./tabfs { };
  tabfs = wrapTabfs tabfs-unwrapped { };
  modorganizer2-linux-installer = callPackage ./modorganizer2-linux-installer { };
  newpipelist = callPackage ./newpipelist { };
}
