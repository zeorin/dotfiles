{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
  makeWrapper,
}:

stdenvNoCC.mkDerivation {
  pname = "doomemacs";
  version = "2.2.0-unstable-2026-06-24";

  src = fetchFromGitHub {
    owner = "doomemacs";
    repo = "core";
    rev = "2698abb722d770a3c62db5090f5b17fa0387a8dd";
    hash = "sha256-PQWHRIlh2aWCiQh+ux5f9HoBRBOs7Y4rh3y/S9CwdAM=";
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

    for dir in docs lisp modules profiles sources static; do
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
