# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{
  pkgs ? (import ../nixpkgs.nix) { },
}:

with pkgs;

{
  base16-tridactyl = callPackage ./base16-tridactyl { };

  codemod = callPackage ./codemod { };

  chemacs2 = callPackage ./chemacs2 { };

  doomemacs = callPackage ./doomemacs { };

  et-book = callPackage ./et-book { };

  emoji-variation-sequences = callPackage ./emoji-variation-sequences { };

  firefox-csshacks = callPackage ./firefox-csshacks { };

  modorganizer2-linux-installer = callPackage ./modorganizer2-linux-installer { };

  newpipelist = callPackage ./newpipelist { };

  nord-dircolors = callPackage ./nord-dircolors { };

  open-in-editor = callPackage ./open-in-editor { };

  polybar-pulseaudio-control = callPackage ./polybar-pulseaudio-control { };
}
