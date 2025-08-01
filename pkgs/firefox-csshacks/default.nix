{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:

stdenvNoCC.mkDerivation {
  pname = "firefox-csshacks";
  version = "0-unstable-2025-07-27";

  src = fetchFromGitHub {
    owner = "MrOtherGuy";
    repo = "firefox-csshacks";
    rev = "14d2fa0d0320fa98f7c4334e901d2b34adfc8090";
    hash = "sha256-etgH1ugB6+KGeNFKik2ArE/yU1uryjE+fkJ0RMyWiJo=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    cp -R $src $out
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };
}
