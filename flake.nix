{
  description = "Xandor Schiefer's system configs";

  nixConfig = {
    extra-substituters = [
      "https://cuda-maintainers.cachix.org"
      "https://devenv.cachix.org"
      "https://nix-community.cachix.org"
      "https://noctalia.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  inputs = {
    systems.url = "github:nix-systems/x86_64-linux";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Never grab the very latest, we want to hit the binary cache
    # https://github.com/nix-community/emacs-overlay/issues/122#issuecomment-1002770274
    emacs-overlay.url = "https://github.com/nix-community/emacs-overlay/archive/master@%7B2%20hours%20ago%7D.tar.gz";

    noctalia.url = "github:noctalia-dev/noctalia/cachix";
    noctalia-greeter.url = "github:noctalia-dev/noctalia-greeter";
    noctalia-greeter.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";
    nur.inputs.nixpkgs.follows = "nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    devenv.url = "github:cachix/devenv/latest";

    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, ... }: {
        debug = true;

        systems = import inputs.systems;

        perSystem = { system, pkgs, ... }: {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = builtins.attrValues (import ./overlays { inherit inputs; });
          };
          legacyPackages = import ./pkgs { inherit pkgs; };
          devShells = {
            default = pkgs.mkShell {
              sopsPGPKeyDirs = [
                "${toString ./.}/keys/hosts"
                "${toString ./.}/keys/users"
              ];
              nativeBuildInputs =
                let
                  pkgs' = pkgs.appendOverlays [ inputs.sops-nix.overlays.default ];
                in
                with pkgs';
                [
                  nix-update
                  sops
                  sops-import-keys-hook
                  nixfmt
                ];
            };
          };
        };

        flake = {
          nixosConfigurations =
            let
              myPkgs = (
                { config, ... }: {
                  # imports = [ inputs.nixpkgs.nixosModules.readOnlyPkgs ];
                  nixpkgs.pkgs = withSystem config.nixpkgs.hostPlatform.system ({ pkgs, ... }: pkgs);
                }
              );
            in
            {
              guru = inputs.nixpkgs.lib.nixosSystem {
                specialArgs = { inherit inputs; };
                modules = [
                  ./nixos/guru
                  myPkgs
                ];
              };
              monarch = inputs.nixpkgs.lib.nixosSystem {
                specialArgs = { inherit inputs; };
                modules = [
                  ./nixos/monarch
                  myPkgs
                ];
              };
              ruby = inputs.nixpkgs.lib.nixosSystem {
                specialArgs = { inherit inputs; };
                modules = [
                  ./nixos/ruby
                  myPkgs
                ];
              };
            };
        };
      }
    );
}
