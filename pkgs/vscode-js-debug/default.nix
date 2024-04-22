{ buildNpmPackage, fetchFromGitHub, jq, libsecret, pkg-config, nodePackages }:

buildNpmPackage rec {
  pname = "vscode-js-debug";
  version = "1.88.0";

  src = fetchFromGitHub {
    owner = "microsoft";
    repo = "vscode-js-debug";
    rev = "v${version}";
    hash = "sha256-gmeuRUcdz/4+FtPOblNj5DX3otXNRjHJjhPcCRuWXAY=";
  };

  npmDepsHash = "sha256-M4h2p8GLVjBDla0ile1jKWF6wPSdgcumx2GKm9KGmlw=";

  nativeBuildInputs = [ pkg-config nodePackages.node-gyp ];

  buildInputs = [ libsecret ];

  postPatch = ''
    ${jq}/bin/jq '
      .scripts.postinstall |= empty |             # tries to install playwright, not necessary for build
      .scripts.build |= "gulp dapDebugServer" |   # there is no build script defined
      .bin |= "./dist/src/dapDebugServer.js"      # there is no bin output defined
    ' ${src}/package.json > package.json
  '';

  makeCacheWritable = true;

  npmInstallFlags = [ "--include=dev" ];

  preBuild = ''
    export PATH="node_modules/.bin:$PATH"
  '';
}
