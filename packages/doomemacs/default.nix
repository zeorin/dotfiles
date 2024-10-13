{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  emacs,
  git,
  unstableGitUpdater,
}:

stdenvNoCC.mkDerivation {
  pname = "doomemacs";
  version = "unstable-2024-10-16";

  src = fetchFromGitHub {
    owner = "doomemacs";
    repo = "doomemacs";
    rev = "8b9168de6e6a9cabf13d1c92558e2ef71aa37a72";
    hash = "";
  };

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [ emacs ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -t $out/share/emacs/site-lisp/ -Dm644 \
      early-init.el bin docs lisp modules profiles

    for prog in $out/share/emacs/site-lisp/bin/*; do
      wrapProgram $out/share/emacs/site-lisp/bin/$prog \
        --prefix PATH : "${
          lib.makeBinPath [
            emacs
            git
          ]
        }" \
        --set DOOMDIR : "$out/share/emacs/site-lisp" \
        --set-default DOOMLOCALDIR : "''${XDG_DATA_HOME:-"$HOME/.local/share"}/doomemacs"
    done

    ln -s $out/share/emacs/site-lisp/bin $out/bin

    runHook postInstall
  '';

  passthru.updateScript = unstableGitUpdater { };

  meta = {
    homepage = "https://github.com/doomemacs/doomemacs";
    description = "An Emacs framework for the stubborn martian hacker";
    longDescription = ''
      Doom is a configuration framework for GNU Emacs tailored for Emacs
      bankruptcy veterans who want less framework in their frameworks, a modicum
      of stability (and reproducibility) from their package manager, and the
      performance of a hand rolled config (or better). It can be a foundation
      for your own config or a resource for Emacs enthusiasts to learn more
      about our favorite operating system.
    '';
    license = with lib.licenses; [ mit ];
    maintainers = with lib.maintainers; [ zeorin ];
    platforms = lib.platforms.all;
  };
}
