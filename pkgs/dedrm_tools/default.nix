{
  stdenvNoCC,
  fetchFromGitHub,
  python312,
  ensureNewerSourcesForZipFilesHook,
  unzip,
}:

stdenvNoCC.mkDerivation (finalArgs: {
  pname = "DeDRM_tools";
  version = "10.0.9-unstable-2024-11-10";
  src = fetchFromGitHub {
    owner = "noDRM";
    repo = "DeDRM_tools";
    rev = "v${finalArgs.version}";
    hash = "sha256-BPNnIZwpafNa566BHK9IKG2PHVU8N8HJ4rR3ECSvyps=";
  };

  nativeBuildInputs = [
    python312
    ensureNewerSourcesForZipFilesHook
    unzip
  ];

  buildPhase = ''
    runHook preBuild

    set -e

    python3 ./make_release.py

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir tmp

    unzip DeDRM_tools.zip -d tmp

    cp tmp/DeDRM_plugin.zip $out

    runHook postInstall
  '';
})
