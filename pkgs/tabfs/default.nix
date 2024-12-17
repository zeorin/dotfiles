let
  originalNativeMessenger = "com.rsnous.tabfs";
  originalAddonId = "tabfs@rsnous.com";

in
(
  {
    lib,
    stdenv,
    writeShellScriptBin,
    fetchFromGitHub,
    runCommandLocal,
    tabfs,
    fuse,
    web-ext,
    pass,
    nativeMessenger ? "za.co.xandor.tabfs",
    addonId ? "tabfs@xandor.co.za",
  }:

  let
    pname = "tabfs";
    rev = "e056ff9073470192ef4c8498aaa7e722edae87c2";
    version = builtins.substring 0 7 rev;

    src = fetchFromGitHub {
      owner = "osnr";
      repo = "TabFS";
      inherit rev;
      hash = "sha256-PEb2pk46PWzjA6Bo9aDhxc+vAC6q5l4iCI01U8HodvU=";
    };

  in
  stdenv.mkDerivation {
    inherit pname version src;

    preferLocalBuild = true;

    passAsFile = [ "nativeMessagingManifest" ];

    nativeMessagingManifest = builtins.toJSON {
      name = nativeMessenger;
      description = "TabFS";
      path = "@out@/bin/tabfs";
      type = "stdio";
      allowed_extensions = [ addonId ];
    };

    patches = [ ./dont-kill-all-other-instances-on-start.patch ];

    nativeBuildInputs = [ fuse ];

    preBuild = ''
      makeFlagsArray+=('CFLAGS+=-I${fuse}/include -L${fuse}/lib $(CFLAGS_EXTRA)')
      cd fs/
    '';

    postBuild = ''
      cd ..
      substituteAll "$nativeMessagingManifestPath" nativeMessagingManifest.json
    '';

    installPhase = ''
      mkdir -p "$out"

      install -Dm0755 fs/tabfs "$out/bin/tabfs"
      install -Dm0644 nativeMessagingManifest.json "$out/lib/mozilla/native-messaging-hosts/${nativeMessenger}.json"
      install -Dm0644 "${./extension.xpi}" "$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/${addonId}.xpi"
    '';

    passthru = {
      inherit
        version
        pname
        nativeMessenger
        addonId
        ;
      sign-unlisted-extension = writeShellScriptBin "tabfs-sign-unlisted-extension" ''
        set -euo pipefail

        version="$1"

        build="$(mktemp -d -t "tabfs-sign-unlisted-extension.XXXXXXXXXX")"
        src="$build/source"
        out="$build/out"

        mkdir -p "$src" "$out"

        trap 'rm -rf "$build"' EXIT

        cp -RL --no-preserve=mode,ownership "${src}/extension"/* "$src"

        rm -rf "$src/safari"

        find "$src" \
          -type f \( -iname \*.js -o -iname \*.json \) \
          -exec sed -i \
            -e 's/${originalNativeMessenger}/${nativeMessenger}/' \
            -e 's/${originalAddonId}/${addonId}/' \
            {} \;

        sed -i -e 's/"version": \?"[0-9]\+\.\?[0-9]*"/"version": "'"$version"'"/' "$src/manifest.json"

        ${web-ext}/bin/web-ext sign \
          --source-dir="$src" \
          --artifacts-dir="$out" \
          --use-submission-api \
          --channel=unlisted \
          --api-key="$(${pass}/bin/pass show addons.mozilla.org/issuer)" \
          --api-secret="$(${pass}/bin/pass show addons.mozilla.org/secret)"

        install -Dm0644 "$out"/*.xpi "$(pwd)/pkgs/tabfs/extension.xpi"
      '';
    };
  }
)
