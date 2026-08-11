{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
  makeWrapper,
}:

stdenvNoCC.mkDerivation {
  pname = "doomemacs";
  version = "2.2.2-unstable-2026-08-06";

  src = fetchFromGitHub {
    owner = "doomemacs";
    repo = "core";
    rev = "ad55ed08df3a1d3398d136d07b60ba2ad00fb91b";
    hash = "sha256-+QPxNQSF63eLkw1hODssS0p0hKqCzsmpTs5UhL0pofE=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir $out

    install -m644 -t $out $src/.dir-locals.el
    install -m644 -t $out $src/.doom
    install -m644 -t $out $src/README.md
    install -m644 -t $out $src/LICENSE
    install -m644 -t $out $src/early-init.el

    for dir in docs lisp modules profiles sources static bin; do
      mkdir -p $out/$dir
      cp -r $src/$dir/* $out/$dir/
    done

    for f in $out/bin/*; do
      patchShebangs --host $out/bin $f
    done

    wrapProgram $out/bin/doomscript \
      --set-default EMACSDIR $out

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };
}
