{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:

stdenvNoCC.mkDerivation {
  pname = "doomemacs";
  version = "2.0.9-unstable-2025-05-10";

  src = fetchFromGitHub {
    owner = "doomemacs";
    repo = "doomemacs";
    rev = "66f1b25dac30ca97779e8a05e735e14230556492";
    hash = "sha256-sO9eB4l3DKkvC2PRY1njGVw5SN6DO28nKg9eAIR7QL4=";
  };

  patches = [
    ./dap-js.patch
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    cp -R $src $out
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=branch=master"
    ];
  };
}
