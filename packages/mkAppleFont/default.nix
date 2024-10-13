{
  lib,
  stdenvNoCC,
  p7zip,
}:

args:
stdenvNoCC.mkDerivation (
  args
  // {
    inherit (args) name src;
    nativeBuildInputs = [ p7zip ];
    unpackCmd = "7z x $curSrc";
    postUnpack = ''
      cd $sourceRoot
      7z x *.pkg
      7z x Payload~
      cd ..
    '';
    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
      runHook preInstall

      install -t $out/share/fonts/truetype/ -Dm644 Library/Fonts/*

      runHook postInstall
    '';
    preferLocalBuild = true;
    allowSubstitutes = false;
    meta.license = lib.licenses.unfree;
  }
)
