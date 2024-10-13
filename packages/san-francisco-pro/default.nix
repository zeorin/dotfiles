{
  namespace,
  pkgs,
  fetchurl,
}:

pkgs.${namespace}.mkAppleFont {
  name = "san-francisco-pro";
  src = fetchurl {
    url = "https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg";
    hash = "sha256-IccB0uWWfPCidHYX6sAusuEZX906dVYo8IaqeX7/O88=";
  };
}
