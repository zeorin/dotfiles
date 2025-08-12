{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
  makeWrapper,
}:

stdenvNoCC.mkDerivation {
  pname = "doomemacs";
  version = "2.0.9-unstable-2025-08-11";

  src = fetchFromGitHub {
    owner = "doomemacs";
    repo = "doomemacs";
    rev = "751ac6134b6abe204d9c514d300343b07b26da3c";
    hash = "sha256-9YmWw/AzUtKFvLlfO30eNfZDxBRnJvRwANojjd7YJjg=";
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
