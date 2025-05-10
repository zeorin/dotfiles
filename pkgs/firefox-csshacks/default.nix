{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:

stdenvNoCC.mkDerivation {
  pname = "firefox-csshacks";
  version = "0-unstable-2025-05-10";

  src = fetchFromGitHub {
    owner = "MrOtherGuy";
    repo = "firefox-csshacks";
    rev = "c880ab119af62969cee51bf9043d354b90c015a1";
    hash = "sha256-Rcu2WI5t5iv5dJEZ1hQ9S8/R+3Yv+fNkETLny6+BfZM=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    cp -R $src $out
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=branch=master"
    ];
  };
}
