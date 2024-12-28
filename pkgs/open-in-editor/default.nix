{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  python3,
  makeDesktopItem,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "open-in-editor";
  version = "unstable-2023-06-01";
  src = fetchFromGitHub {
    owner = "dandavison";
    repo = "open-in-editor";
    rev = "e2c2eabf9da125316d663661dd6bedf8a19a2fb5";
    hash = "sha256-BflH/4h08rrRmeVjy+9/aVzMW/vVzSRKKGKAVWu1m1s=";
  };
  dontConfigure = true;
  dontBuild = true;
  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    mkdir -p $out/bin
    makeWrapper $src/open-in-editor $out/bin/open-in-editor \
      --prefix PATH : ${lib.makeBinPath [ python3 ]}
  '';
  desktopItem = makeDesktopItem {
    name = finalAttrs.pname;
    desktopName = "OpenInEditor";
    genericName = "Open a file at a certain position";
    comment = "Opens URLs of the type file-line-column://<path>[:<line>[:<column>]] in the configured editor and positions the cursor";
    type = "Application";
    terminal = false;
    noDisplay = true;
    icon = "text-editor";
    exec = "open-in-editor %U";
    categories = [
      "Utility"
      "Core"
    ];
    startupNotify = true;
    mimeTypes = [
      "x-scheme-handler/file-line-column"
      "x-scheme-handler/editor"
    ];
  };
})
