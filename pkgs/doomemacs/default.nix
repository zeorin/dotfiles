{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
  makeWrapper,
}:

stdenvNoCC.mkDerivation {
  pname = "doomemacs";
  version = "2.0.9-unstable-2026-01-21";

  src = fetchFromGitHub {
    owner = "doomemacs";
    repo = "doomemacs";
    rev = "57818a6da90fbef39ff80d62fab2cd319496c3b9";
    hash = "sha256-VvC4rgAAaFnYLCdcUoz7dTE3kuBNuHIc+GlXOrPCxpg=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir $out

    install -m644 -t $out $src/.dir-locals.el
    install -m644 -t $out $src/.doom
    install -m644 -t $out $src/README.md
    install -m644 -t $out $src/early-init.el

    for dir in docs lisp modules profiles static; do
      cp -r $src/$dir $out/$dir
    done

    mkdir $out/bin

    for f in doom doomscript org-capture; do
      makeWrapper $src/bin/$f $out/bin/$f \
        --set-default EMACSDIR $out
    done

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };
}
