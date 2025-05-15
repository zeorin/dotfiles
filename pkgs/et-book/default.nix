{
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation rec {
  pname = "et-book";
  version = "0-unstable-2019-07-26";

  src = fetchFromGitHub {
    owner = "edwardtufte";
    repo = pname;
    rev = "24d3a3bbfc880095d3df2b9e9d60d05819138e89";
    hash = "sha256-9maMYSjVNrAo+0++28bXwn9719jFI1nYh02iu1yYF64=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype
    cp -t $out/share/fonts/truetype source/4-ttf/*.ttf

    runHook postInstall
  '';
}
