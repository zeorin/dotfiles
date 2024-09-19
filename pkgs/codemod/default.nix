{
  fetchFromGitHub,
  stdenv,
  stdenvNoCC,
  nodejs,
  nodePackages,
  makeWrapper,
  cacert,
  element-desktop,
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

  npmDeps = stdenvNoCC.mkDerivation {
    pname = "${finalAttrs.pname}-pnpm-deps";
    inherit (finalAttrs) src version;

    nativeBuildInputs = [
      nodePackages.pnpm
      cacert
    ];

    installPhase = ''
      export HOME=$(mktemp -d)

      pnpm config set store-dir $out
      pnpm install --frozen-lockfile --ignore-script
    '';

    dontBuild = true;
    dontFixup = true;
    outputHashMode = "recursive";
    outputHash =
      {
        x86_64-linux = "sha256-DC7dajfLoihTOK7ZMrN44Oj8dYSpMjwp+z9xTN/feBs=";
      }
      .${stdenv.system} or (throw "Unsupported system: ${stdenv.system}");
  };

  nativeBuildInputs = [
    nodePackages.pnpm
    cacert
  ];

  buildInputs = [ makeWrapper ];

  buildPhase = ''
    runHook preBuild

    export HOME=$(mktemp -d)

    pnpm config set store-dir ${finalAttrs.npmDeps}
    pnpm install --offline --frozen-lockfile --ignore-script

    rm -rf node_modules/.pnpm/keytar@7.9.0/node_modules/keytar
    ln -s ${element-desktop.keytar} node_modules/.pnpm/keytar@7.9.0/node_modules/keytar

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
