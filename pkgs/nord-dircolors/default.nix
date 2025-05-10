{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "nord-dircolors";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "nordtheme";
    repo = "dircolors";
    rev = "v${finalAttrs.version}";
    hash = "sha256-/1PZjKg56tgzmZuSA14zV2Kzi1W2NOyg+caIG5tRLrE=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    cp -R $src $out
  '';

  passthru.updateScript = nix-update-script { };
})
