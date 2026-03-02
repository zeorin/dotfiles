{
  fetchFromGitHub,
  nix-update-script,
  pkgs,
}:

let
  inherit (pkgs.tmuxPlugins) mkTmuxPlugin;

in
{
  mighty-scroll = mkTmuxPlugin {
    pluginName = "mighty-scroll";
    version = "0-unstable-2025-12-10";
    rtpFilePath = "mighty-scroll.tmux";
    src = fetchFromGitHub {
      owner = "noscript";
      repo = "tmux-mighty-scroll";
      rev = "fa5db0718e9e9f7278520ecf63b96b84b0cc57d6";
      hash = "sha256-F62qF3rGhvSIP5MKamTZHswt8rvuBspRCi2iDjcZuTI=";
    };
    buildPhase = ''
      mkdir -p $out/bin

      cc -Wall -Wextra -Werror -Wconversion -pedantic -std=c99 -O3 $src/pscheck.c -o $out/bin/pscheck
    '';
    passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };
  };

  transient-status = mkTmuxPlugin {
    pluginName = "transient-status";
    version = "0-unstable-2023-12-26";
    rtpFilePath = "main.tmux";
    src = fetchFromGitHub {
      owner = "TheSast";
      repo = "tmux-transient-status";
      rev = "c3fcd5180999a7afc075d2dd37d37d1b1b82f7e8";
      hash = "sha256-fOIn8hVVBDFVLwzmPZP+Bf3ccxy/hsAnKIXYD9yv3BE=";
    };
    passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };
  };
}
