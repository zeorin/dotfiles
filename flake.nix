{
  description = "Xandor Schiefer's system configs";

  inputs = {
    systems.url = "github:nix-systems/x86_64-linux";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";

    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";

    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    nix-alien.url = "github:thiagokokada/nix-alien";

    nixos-vscode-server.url = "github:nix-community/nixos-vscode-server";
    nixos-vscode-server.inputs.nixpkgs.follows = "nixpkgs";

    doomemacs.url = "github:zeorin/doomemacs/feat/dap-js";
    doomemacs.flake = false;

    nord-dircolors.url = "github:nordtheme/dircolors";
    nord-dircolors.flake = false;

    firefox-csshacks.url = "github:MrOtherGuy/firefox-csshacks";
    firefox-csshacks.flake = false;

    pulseaudio-control.url = "github:marioortizmanero/polybar-pulseaudio-control";
    pulseaudio-control.flake = false;

    chemacs.url = "github:plexus/chemacs2";
    chemacs.flake = false;

    base16-tridactyl.url = "github:tridactyl/base16-tridactyl";
    base16-tridactyl.flake = false;

    emoji-variation-sequences.url = "https://www.unicode.org/Public/15.0.0/ucd/emoji/emoji-variation-sequences.txt";
    emoji-variation-sequences.flake = false;
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      flake-utils,
      ...
    }@inputs:
    let
      inherit (self) outputs;
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        # Your custom packages
        # Acessible through 'nix build', 'nix shell', etc
        packages = import ./pkgs { inherit pkgs; };
        # Devshell for bootstrapping
        # Acessible through 'nix develop' or 'nix-shell' (legacy)
        devShells = import ./shell.nix {
          pkgs = pkgs.appendOverlays (builtins.attrValues outputs.overlays);
        };
      }
    )
    // {
      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };

      # Reusable nixos modules you might want to export
      # These are usually stuff you would upstream into nixpkgs
      nixosModules = import ./modules/nixos;

      # Reusable home-manager modules you might want to export
      # These are usually stuff you would upstream into home-manager
      homeManagerModules = import ./modules/home-manager;

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        guru = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs;
          };
          modules = [ ./nixos/guru ];
        };
        monarch = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs;
          };
          modules = [ ./nixos/monarch ];
        };
      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username@your-hostname'
      homeConfigurations =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in
        {
          "zeorin@guru" = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = {
              inherit inputs outputs;
            };
            modules = [ ./home-manager/home.nix ];
          };
          "zeorin@monarch" = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = {
              inherit inputs outputs;
            };
            modules = [ ./home-manager/home.nix ];
          };
        };
    };
}
