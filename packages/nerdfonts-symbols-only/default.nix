{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  nerdfonts,
  symlinkJoin,
  fetchurl,
}:

symlinkJoin {
  name = "${nerdfonts.pname}-symbols-only-${nerdfonts.version}";
  paths = [
    (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
    # Set FontConfig to use the symbols only font as a fallback for most
    # monospaced fonts, this gives us the symbols even for fonts that we
    # didn't install Nerd Fonts versions of. The Symbols may not be perfectly
    # suited to that font (the patched fonts usually have adjustments to the
    # Symbols specifically for that font), but it's better than nothing.
    (stdenvNoCC.mkDerivation (finalAttrs: {
      inherit (nerdfonts) version;
      pname = "${nerdfonts.pname}-symbols-only-fontconfig";

      src = fetchurl {
        url = "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/refs/tags/v${finalAttrs.version}/10-nerd-font-symbols.conf";
        hash = "sha256-ZgHkMcXEPYDfzjdRR7KX3ws2u01GWUj48heMHaiaznY=";
      };

      dontUnpack = true;
      dontConfigure = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall

        install -t $out/etc/fonts/conf.d/ -Dm644 $src

        runHook postInstall
      '';
    }))
  ];
}
