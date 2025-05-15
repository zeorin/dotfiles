{
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:

stdenvNoCC.mkDerivation {
  pname = "doomemacs";
  version = "2.0.9-unstable-2025-05-15";

  src = fetchFromGitHub {
    owner = "doomemacs";
    repo = "doomemacs";
    rev = "fabce333e003324cbfafa01fa0cd967a2712df1d";
    hash = "sha256-kJQ9DLn1kOGIOoXk1HBBQg0/AMNFYBo26nkveD1dCtU=";
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
