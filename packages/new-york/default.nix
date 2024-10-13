{
  namespace,
  pkgs,
  fetchurl,
}:

pkgs.${namespace}.mkAppleFont {
  name = "new-york";
  src = fetchurl {
    url = "https://devimages-cdn.apple.com/design/resources/download/NY.dmg";
    hash = "sha256-HC7ttFJswPMm+Lfql49aQzdWR2osjFYHJTdgjtuI+PQ=";
  };
}
