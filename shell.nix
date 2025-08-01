# Shell for bootstrapping flake-enabled nix and home-manager
# You can enter it through 'nix develop' or (legacy) 'nix-shell'

{
  pkgs ? (import ./nixpkgs.nix) { },
}:
{
  default = pkgs.mkShell {
    sopsPGPKeyDirs = [
      "${toString ./.}/keys/hosts"
      "${toString ./.}/keys/users"
    ];

    # Enable experimental features without having to specify the argument
    NIX_CONFIG = "experimental-features = nix-command flakes";
    nativeBuildInputs = with pkgs; [
      nix
      home-manager
      git
      nix-update
      sops
      sops-import-keys-hook
      oama
    ];
  };
}
