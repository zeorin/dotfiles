{
  description = "Xandor Schiefer's system configs";

  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  inputs = {
    systems.url = "github:nix-systems/x86_64-linux";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";
    nur.inputs.nixpkgs.follows = "nixpkgs-unstable";

    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";

    devenv.url = "github:cachix/devenv/v1.11.2";

    hyprland.url = "github:hyprwm/Hyprland";

    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    nix-software-center.url = "github:zeorin/nix-software-center";
    nix-software-center.inputs.nixpkgs.follows = "nixpkgs";

    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

    disko-raspberrypi.url = "github:nix-community/disko";
    disko-raspberrypi.inputs.nixpkgs.follows = "nixos-raspberrypi/nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        # Your custom packages
        # Acessible through 'nix build', 'nix shell', etc
        packages = import ./pkgs { pkgs = pkgs.appendOverlays [ self.outputs.overlays.additions ]; };
        # Devshell for bootstrapping
        # Acessible through 'nix develop' or 'nix-shell' (legacy)
        devShells = import ./shell.nix {
          pkgs = pkgs.appendOverlays (
            (builtins.attrValues self.outputs.overlays) ++ [ inputs.sops-nix.overlays.default ]
          );
        };
      }
    )
    // {
      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays inputs;

      # Reusable nixos modules you might want to export
      # These are usually stuff you would upstream into nixpkgs
      nixosModules = import ./modules/nixos;

      # Reusable home-manager modules you might want to export
      # These are usually stuff you would upstream into home-manager
      homeModules = import ./modules/home-manager;

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        guru = nixpkgs.lib.nixosSystem {
          specialArgs = inputs;
          modules = [ ./nixos/guru ];
        };
        monarch = nixpkgs.lib.nixosSystem {
          specialArgs = inputs;
          modules = [ ./nixos/monarch ];
        };
        ruby = nixpkgs.lib.nixosSystem {
          specialArgs = inputs;
          modules = [ ./nixos/ruby ];
        };
        tv = inputs.nixos-raspberrypi.lib.nixosSystemFull {
          specialArgs = inputs;
          modules = [ ./nixos/tv ];
        };
      };

      installerImages =
        let
          mkNixOSRPiInstaller =
            modules:
            inputs.nixos-raspberrypi.lib.nixosInstaller {
              specialArgs = inputs;
              modules = [
                inputs.nixos-raspberrypi.inputs.nixos-images.nixosModules.sdimage-installer
                (
                  {
                    config,
                    lib,
                    modulesPath,
                    ...
                  }:
                  {
                    disabledModules = [
                      # disable the sd-image module that nixos-images uses
                      (modulesPath + "/installer/sd-card/sd-image-aarch64-installer.nix")
                    ];
                    # nixos-images sets this with `mkForce`, thus `mkOverride 40`
                    image.baseName =
                      let
                        cfg = config.boot.loader.raspberryPi;
                      in
                      lib.mkOverride 40 "nixos-installer-rpi${cfg.variant}-${cfg.bootloader}";
                  }
                )
              ]
              ++ modules;
            };
        in
        {
          tv = (mkNixOSRPiInstaller [ ./nixos/tv ]).config.system.build.sdImage;
        };
    };
}
