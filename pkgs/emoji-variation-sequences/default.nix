{
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "emoji-variation-sequences";
  version = "18.0.0";

  src = fetchurl {
    url = "https://www.unicode.org/Public/${finalAttrs.version}/ucd/emoji/emoji-variation-sequences.txt";
    hash = "sha256-/xcHVkqh8bL89OyS1gnUyyaUC8DU3PB/UyitaHnoTaM=";
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    cp $src $out
  '';
})
