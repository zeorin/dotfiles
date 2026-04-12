{
  stdenvNoCC,
  fetchFromGitHub,
  xorg,
  nix-update-script,
  extraLayouts ? { },
}:

let

  xkeyboardconfig = xorg.xkeyboardconfig_custom {
    layouts = extraLayouts;
  };

in

stdenvNoCC.mkDerivation {
  pname = "big-bag-kbd-trix-xkb";
  version = "0-unstable-2026-01-08";

  src = fetchFromGitHub {
    owner = "DreymaR";
    repo = "BigBagKbdTrixXKB";
    rev = "2b58b33922c7aaa3171cc597c32848ad70b7edaa";
    hash = "sha256-jjgLmfC4JWBuC2Bakt+ymIqRWKwazBWY3FCOqxgNlew=";
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

    rm $out/share/X11/setkb.sh

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };
}
