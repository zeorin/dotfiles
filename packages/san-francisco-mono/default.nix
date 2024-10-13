{
  namespace,
  pkgs,
  fetchurl,
}:

pkgs.${namespace}.mkAppleFont {
  name = "san-francisco-mono";
  src = fetchurl {
    url = "https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg";
    hash = "sha256-bUoLeOOqzQb5E/ZCzq0cfbSvNO1IhW1xcaLgtV2aeUU=";
  };
}
