{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:

stdenvNoCC.mkDerivation {
  pname = "chemacs2";
  version = "unstable-2025-05-10";

  src = fetchFromGitHub {
    owner = "plexus";
    repo = "chemacs2";
    rev = "c2d700b784c793cc82131ef86323801b8d6e67bb";
    hash = "sha256-/WtacZPr45lurS0hv+W8UGzsXY3RujkU5oGGGqjqG0Q=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    cp -R $src $out
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=branch=main"
    ];
  };
}
