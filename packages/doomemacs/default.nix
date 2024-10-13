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
    hash = "sha256-bIXSqOlmJL/PZUou2dx7Lj2wDkF98V9XiVsP1ffnbaw=";
  };

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [ emacs ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/emacs/site-lisp

    for file in early-init.el bin docs lisp modules profiles templates; do
      cp -R $file $out/share/emacs/site-lisp/
    done

    for prog in $out/share/emacs/site-lisp/bin/*; do
      if [ -f $prog ] && [ -x $prog ]; then
      wrapProgram $prog \
        --prefix PATH : "${
          lib.makeBinPath [
            emacs
            git
          ]
        }" \
        --set EMACSDIR "$out/share/emacs/site-lisp" \
        --set-default DOOMLOCALDIR "${"\${XDG_DATA_HOME:-\"${"\${HOME}"}/.local/share\"}/doomemacs"}"
      fi
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
