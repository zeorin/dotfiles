{
  lib,
  fetchFromGitHub,
  stdenv,
  nodejs,
  makeWrapper,
  cacert,
  element-desktop,
  pnpm_9,
  prisma-engines,
  nix-update-script,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "codemod";
  version = "0.18.9";

  src = fetchFromGitHub {
    owner = "codemod-com";
    repo = "codemod";
    rev = "codemod@${finalAttrs.version}";
    hash = "sha256-DkR1EYwC1uHcagZAVNNiw8p26uxmTYvSGYTaeWRVCnA=";
  };

  pnpmDeps = pnpm_9.fetchDeps {
    inherit (finalAttrs) pname version src;
    hash = "sha256-aNnPOh7bZ3BGJHzLBykqz5e+9aUHgIh7olva0NvtTeA=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm_9.configHook
    cacert
  ];

  buildInputs = [ makeWrapper ];

  PRISMA_SCHEMA_ENGINE_BINARY = lib.getExe' prisma-engines "schema-engine";
  PRISMA_QUERY_ENGINE_BINARY = lib.getExe' prisma-engines "query-engine";
  PRISMA_QUERY_ENGINE_LIBRARY = "${prisma-engines}/lib/libquery_engine.node";
  PRISMA_INTROSPECTION_ENGINE_BINARY = lib.getExe' prisma-engines "introspection-engine";
  PRISMA_FMT_BINARY = lib.getExe' prisma-engines "prisma-fmt";

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

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version-regex"
      "codemod@(.*)"
    ];
  };
})
