{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  inkscape,
  xorg,
  jdupes,
  unstableGitUpdater,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "colloid-nord-cursor-theme";
  version = "unstable-2024-02-28";

  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "Colloid-icon-theme";
    rev = "ebca4f67d3fe199ae915dd2a36128e2302c026b6";
    hash = "sha256-xpRgOt/FqZSbtOlZKlZS1ILQn6OAwqKAXX3hj41Wo+0=";
  };

  sourceRoot = "${finalAttrs.src.name}/cursors";

  nativeBuildInputs = [
    inkscape
    xorg.xcursorgen
    jdupes
  ];

  postPatch = ''
    sed -i \
      -e 's/#000000/#2e3440/g' \
      -e 's/#1191f4/#5e81ac/g' \
      -e 's/#14adf6/#88c0d0/g' \
      -e 's/#1a1a1a/#2e3440/g' \
      -e 's/#1b9aeb/#5e81ac/g' \
      -e 's/#2a2a2a/#3b4252/g' \
      -e 's/#2c2c2c/#3b4252/g' \
      -e 's/#3bbd1c/#a3be8c/g' \
      -e 's/#4caf50/#a3be8c/g' \
      -e 's/#52cf30/#a3be8c/g' \
      -e 's/#5b9bf8/#81a1c1/g' \
      -e 's/#666666/#4c566a/g' \
      -e 's/#6fce55/#a3be8c/g' \
      -e 's/#ac44ca/#b48ead/g' \
      -e 's/#b452cb/#b48ead/g' \
      -e 's/#c7c7c7/#d8dee9/g' \
      -e 's/#ca70e1/#b48ead/g' \
      -e 's/#cecece/#d8dee9/g' \
      -e 's/#d1d1d1/#d8dee9/g' \
      -e 's/#dcdcdc/#d8dee9/g' \
      -e 's/#ed1515/#bf616a/g' \
      -e 's/#f5f5f5/#e5e9f0/g' \
      -e 's/#f67400/#d08770/g' \
      -e 's/#f83f31/#bf616a/g' \
      -e 's/#faa91e/#d08770/g' \
      -e 's/#fbb114/#d08770/g' \
      -e 's/#fbd939/#ebcb8b/g' \
      -e 's/#fdcf01/#ebcb8b/g' \
      -e 's/#ff2a2a/#bf616a/g' \
      -e 's/#ff4332/#bf616a/g' \
      -e 's/#ff645d/#bf616a/g' \
      -e 's/#ff9508/#d08770/g' \
      -e 's/#ffaa07/#d08770/g' \
      -e 's/#ffd305/#ebcb8b/g' \
      -e 's/#ffffff/#eceff4/g' \
      src/svg/*.svg \
      src/svg-white/*.svg

    patchShebangs build.sh

    substituteInPlace build.sh \
      --replace 'THEME="Colloid Cursors"' 'THEME="Colloid-nord-light-cursors"' \
      --replace 'THEME="Colloid-dark Cursors"' 'THEME="Colloid-nord-dark-cursors"'

    patchShebangs install.sh

    substituteInPlace install.sh \
      --replace '$HOME/.local' $out \
      --replace '$THEME_NAME-cursors' '$THEME_NAME-nord-light-cursors' \
      --replace '$THEME_NAME-dark-cursors' '$THEME_NAME-nord-dark-cursors'
  '';

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    ./build.sh

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/icons

    ./install.sh

    jdupes --quiet --link-soft --recurse $out/share

    runHook postInstall
  '';

  passthru.updateScript = unstableGitUpdater { };

  meta = {
    homepage = "https://github.com/nordtheme/dircolors";
    description = "An arctic, north-bluish clean and elegant dircolors theme. ";
    license = with lib.licenses; [ mit ];
    maintainers = with lib.maintainers; [ zeorin ];
    platforms = lib.platforms.all;
  };
})
