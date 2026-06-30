{
  stdenvNoCC,
  fetchFromGitHub,
  xkeyboardconfig_custom,
  nix-update-script,
  extraLayouts ? { },
}:

let

  xkeyboardconfig = xkeyboardconfig_custom {
    layouts = extraLayouts;
  };

in

stdenvNoCC.mkDerivation {
  pname = "big-bag-kbd-trix-xkb";
  version = "0-unstable-2026-01-31";

  src = fetchFromGitHub {
    owner = "DreymaR";
    repo = "BigBagKbdTrixXKB";
    rev = "bcbf7f09d4277419f49b1c778d0d9559619f6bfa";
    hash = "sha256-UyODm668nNue6HGfwZKE5BZeN9IG3LxBfcCt2aqaDaU=";
  };

  postPatch = ''
    substituteInPlace install-dreymar-xmod.sh \
      --replace-fail "DModFix='d'" "DModFix='''" \
      --replace-fail "cp -aZ" "cp -aZ --no-preserve=mode"

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

    rm $out/share/X11/setkb.sh

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };
}
