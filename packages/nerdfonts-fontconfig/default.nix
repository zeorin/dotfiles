{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  nerdfonts,
}:

stdenvNoCC.mkDerivation {
  inherit (nerdfonts) version src;
  pname = "${nerdfonts.pname}-fontconfig";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -t $out/etc/fonts/conf.d/ -Dm644 $src/10-nerd-font-symbols.conf

    runHook postInstall
  '';
}
