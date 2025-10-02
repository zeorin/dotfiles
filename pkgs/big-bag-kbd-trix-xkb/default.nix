{
  lib,
  ed,
  automake,
  stdenvNoCC,
  fetchFromGitHub,
  xorg,
  nix-update-script,
  extraLayouts ? null,
}:

let
  # taken from pkgs/servers/x11/xorg/overrides.nix
  patchIn = name: layout: ''
    # install layout files
    ${lib.optionalString (layout.compatFile != null) "cp '${layout.compatFile}'   'compat/${name}'"}
    ${lib.optionalString (layout.geometryFile != null) "cp '${layout.geometryFile}' 'geometry/${name}'"}
    ${lib.optionalString (layout.keycodesFile != null) "cp '${layout.keycodesFile}' 'keycodes/${name}'"}
    ${lib.optionalString (layout.symbolsFile != null) "cp '${layout.symbolsFile}'  'symbols/${name}'"}
    ${lib.optionalString (layout.typesFile != null) "cp '${layout.typesFile}'    'types/${name}'"}

    # add model description
    ${ed}/bin/ed -v rules/base.xml <<EOF
    /<\/modelList>
    -
    a
    <model>
      <configItem>
        <name>${name}</name>
        <description>${layout.description}</description>
        <vendor>${layout.description}</vendor>
      </configItem>
    </model>
    .
    w
    EOF

    # add layout description
    ${ed}/bin/ed -v rules/base.xml <<EOF
    /<\/layoutList>
    -
    a
    <layout>
      <configItem>
        <name>${name}</name>
        <shortDescription>${name}</shortDescription>
        <description>${layout.description}</description>
        <languageList>
          ${lib.concatMapStrings (lang: "<iso639Id>${lang}</iso639Id>\n") layout.languages}
        </languageList>
      </configItem>
      <variantList/>
    </layout>
    .
    w
    EOF
  '';

  xkeyboardconfig =
    if extraLayouts == null then
      xorg.xkeyboardconfig
    else
      xorg.xkeyboardconfig.overrideAttrs (old: {
        nativeBuildInputs = old.nativeBuildInputs ++ [ automake ];
        postPatch = lib.concatStrings (lib.mapAttrsToList patchIn extraLayouts);
      });

in

stdenvNoCC.mkDerivation {
  pname = "big-bag-kbd-trix-xkb";
  version = "0-unstable-2025-10-01";

  src = fetchFromGitHub {
    owner = "DreymaR";
    repo = "BigBagKbdTrixXKB";
    rev = "00d563c92598eb72a9beb0aa527e06577a77d70b";
    hash = "sha256-812AC9HUixKEHPQDfe1orYWnQskCgltCCgkqNGKnLAo=";
  };

  postPatch = ''
    substituteInPlace install-dreymar-xmod.sh \
      --replace-fail "DModFix='d'" "DModFix='''" \
      --replace-fail "cp -a" "cp -a --no-preserve=mode"

    patchShebangs install-dreymar-xmod.sh
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/X11

    ln -s $out/share $out/etc

    ./install-dreymar-xmod.sh -ns \
      -c ${xkeyboardconfig}/share/X11 \
      -i $out/share/X11

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };
}
