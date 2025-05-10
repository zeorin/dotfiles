{
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "emoji-variation-sequences";
  version = "16.0.0";

  src = fetchurl {
    url = "https://www.unicode.org/Public/${finalAttrs.version}/ucd/emoji/emoji-variation-sequences.txt";
    hash = "sha256-cdk+wBUBE3GgJ7orwKYxVdOBxuC5SlhsGoiklADNaGQ=";
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    cp $src $out
  '';
})
