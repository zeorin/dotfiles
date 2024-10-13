{
  namespace,
  pkgs,
  fetchurl,
}:

pkgs.${namespace}.mkAppleFont {
  name = "san-francisco-compact";
  src = fetchurl {
    url = "https://devimages-cdn.apple.com/design/resources/download/SF-Compact.dmg";
    hash = "sha256-PlraM6SwH8sTxnVBo6Lqt9B6tAZDC//VCPwr/PNcnlk=";
  };
}
