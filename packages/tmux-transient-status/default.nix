{
  lib,
  tmuxPlugins,
  fetchFromGitHub,
  unstableGitUpdater,
}:

tmuxPlugins.mkTmuxPlugin {
  pluginName = "transient-status";
  version = "unstable-2024-07-07";

  rtpFilePath = "main.tmux";

  src = fetchFromGitHub {
    owner = "TheSast";
    repo = "tmux-transient-status";
    rev = "c3fcd5180999a7afc075d2dd37d37d1b1b82f7e8";
    sha256 = "sha256-fOIn8hVVBDFVLwzmPZP+Bf3ccxy/hsAnKIXYD9yv3BE=";
  };

  passthru.updateScript = unstableGitUpdater { };

  meta = {
    homepage = "https://github.com/doomemacs/doomemacs";
    description = "Automatically make your tmux status bar vanish when unneeded";
    license = with lib.licenses; [ asl20 ];
    maintainers = with lib.maintainers; [ zeorin ];
    platforms = lib.platforms.all;
  };
}
