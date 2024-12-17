{
  fetchFromGitHub,
  stdenv,
  stdenvNoCC,
  nodejs,
  nodePackages,
  makeWrapper,
  cacert,
  element-desktop,
  pnpm_9,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "codemod-cli";
  version = "1.0.3";

  src = fetchFromGitHub {
    owner = "codemod-com";
    repo = "codemod";
    rev = "v${finalAttrs.version}";
    hash = "sha256-mnj6IBrAOekw6xNDS36Vwyi0t89u2ImE3RbcJZD1lCQ=";
  };

  pnpmDeps = pnpm_9.fetchDeps {
    inherit (finalAttrs) pname version src;
    hash = "sha256-y5HISy1FCrYgbhNOEwdOSuQMaxJcrCv7tX9NdctyZJk=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm_9.configHook
    cacert
  ];

  buildInputs = [ makeWrapper ];

  buildPhase = ''
    runHook preBuild

    # rm -rf node_modules/.pnpm/keytar@7.9.0/node_modules/keytar
    # ln -s ${element-desktop.keytar} node_modules/.pnpm/keytar@7.9.0/node_modules/keytar

    pnpm run build --filter codemod

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib

    cp -R node_modules apps $out/lib

    patchShebangs $out/{*,.*}

    makeWrapper ${nodejs}/bin/node $out/bin/codemod --add-flags $out/lib/apps/cli/dist/index.cjs

    runHook postInstall
  '';

  dontFixup = true;
})
