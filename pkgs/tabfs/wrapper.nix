{
  lib,
  stdenvNoCC,
  lndir,
  makeWrapper,
}:

tabfs:

let
  inherit (tabfs.passthru) pname version nativeMessenger;

  wrapper =
    {
      mountDir ? "",
    }:
    if mountDir == "" then
      tabfs
    else
      stdenvNoCC.mkDerivation {
        inherit pname version;

        nativeBuildInputs = [
          lndir
          makeWrapper
        ];

        dontUnpack = true;
        dontConfigure = true;

        buildPhase = ''
          makeWrapper "${tabfs}/bin/tabfs" "tabfs" \
            --set TABFS_MOUNT_DIR "${mountDir}"
        '';

        installPhase = ''
          mkdir -p "$out"
          lndir -silent "${tabfs}" "$out"

          rm "$out/bin/tabfs"

          install -Dm0755 tabfs "$out/bin/tabfs"

          rm "$out/lib/mozilla/native-messaging-hosts/${nativeMessenger}.json"

          sed \
            -e 's#${tabfs}#'"$out"'#' \
            "${tabfs}/lib/mozilla/native-messaging-hosts/${nativeMessenger}.json" \
            > "$out/lib/mozilla/native-messaging-hosts/${nativeMessenger}.json"
        '';

        dontFixup = true;

        inherit (tabfs) passthru;
      };
in
lib.makeOverridable wrapper
