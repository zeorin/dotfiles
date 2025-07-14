{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
  makeWrapper,
}:

stdenvNoCC.mkDerivation {
  pname = "doomemacs";
  version = "2.0.9-unstable-2025-07-13";

  src = fetchFromGitHub {
    owner = "doomemacs";
    repo = "doomemacs";
    rev = "ed9190ef005829c7a2331e12fb36207794c5ad75";
    hash = "sha256-nU/UmyYQAcPHGJEC1mVm40LY3LlA7df9khckbvMB5x8=";
  };

  patches = [
    ./dap-js.patch
  ];

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
