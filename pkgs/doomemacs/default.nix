{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
  makeWrapper,
}:

stdenvNoCC.mkDerivation {
  pname = "doomemacs";
  version = "2.0.9-unstable-2025-05-22";

  src = fetchFromGitHub {
    owner = "doomemacs";
    repo = "doomemacs";
    rev = "cfea950e60961e45fc43a820d855eb6212856126";
    hash = "sha256-hPaLeu/1CoWADviDwcBxV7VTRFb831TF2ND7ArLzpfQ=";
  };

  patches = [
    ./dap-js.patch
  ];

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir $out

    install -m644 -t $out $src/.dir-locals.el
    install -m644 -t $out $src/.doomrc
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

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=branch=master"
    ];
  };
}
