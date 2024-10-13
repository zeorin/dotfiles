{
  description = "Xandor Schiefer's Nix Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = "github:nix-community/NUR";

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      lib = inputs.snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;

        snowfall = {
          namespace = "zeorin";
        };

        systems.modules.nixos = [ inputs.home-manager.nixosModules.home-manager ];
      };
    in
    lib.mkFlake {
      channels-config = {
        allowUnfreePredicate =
          pkg:
          (builtins.elem (lib.getName pkg) [
            "steam" # protontricks
            "steam-run" # protontricks
            "steam-original" # protontricks
            "corefonts"
            "vista-fonts"
            "xkcd-font"
            "san-francisco-pro"
            "san-francisco-compact"
            "san-francisco-mono"
            "new-york"
            "symbola"
            "spotify"
            "google-chrome"
            "netflix-via-google-chrome"
            "netflix-icon"
            "enhancer-for-youtube"
            "slack"
            "discord"
            "skypeforlinux"
            "zoom"
            "mfcj2340dwpdrv"
          ])
          || (lib.hasPrefix "libretro-" (lib.getName pkg)) # retroarchFull
        ;
      };
    };
}
