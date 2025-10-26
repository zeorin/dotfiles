# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{
  pkgs ? (import ../nixpkgs.nix) { },
}:

with pkgs;

{
  base16-tridactyl = callPackage ./base16-tridactyl { };

  big-bag-kbd-trix-xkb = callPackage ./big-bag-kbd-trix-xkb { };

  codemod = callPackage ./codemod { };

  chemacs2 = callPackage ./chemacs2 { };

  doomemacs = callPackage ./doomemacs { };

  et-book = callPackage ./et-book { };

  emoji-variation-sequences = callPackage ./emoji-variation-sequences { };

  hyprland-preview-share-picker = callPackage ./hyprland-preview-share-picker { };

  firefox-csshacks = callPackage ./firefox-csshacks { };

  modorganizer2-linux-installer = callPackage ./modorganizer2-linux-installer { };

  newpipelist = callPackage ./newpipelist { };

  notion-app = callPackage ./notion-app { };

  nord-dircolors = callPackage ./nord-dircolors { };

  open-in-editor = callPackage ./open-in-editor { };
}
