{
  lib,
  symlinkJoin,
  stdenvNoCC,
  fetchurl,
  bash,
  python3,
}:

let
  python = python3.withPackages (
    p: with p; [
      i2c-tools
      libgpiod
    ]
  );

  sources = lib.attrsets.mapAttrs (
    path: hash:
    fetchurl {
      inherit hash;
      url = "https://download.argon40.com/${path}";
      downloadToTemp = true;
      postFetch = ''
        install -m 0644 -D $downloadedFile "$out/${path}"
      '';
      recursiveHash = true;
    }
  ) (lib.importJSON ./sources.json);

  scripts = symlinkJoin {
    name = "scripts";
    paths = lib.attrsets.attrValues sources;
  };

in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "argononed";
  version = "unstable-2025-11-22";

  srcs = [
    (fetchurl {
      url = "https://download.argon40.com/scripts/argononed.py";
      hash = "sha256-NfGalcLjCcOcHzUJ9AymiVBV3UfB1coN1OKdLqyLP7Q=";
    })
    (fetchurl {
      url = "https://download.argon40.com/scripts/argonpowerbutton-libgpiod.py";
      hash = "sha256-RLiIrOl30PHJZO7KHaq8w5AMBqOPNRqZytCM+VjB3t8=";
    })
    (fetchurl {
      url = "https://download.argon40.com/scripts/argonsysinfo.py";
      hash = "sha256-DlofcNESZ/CcILj94btdxEw+SfH5EqSy3yOLoIByPkw=";
    })
    (fetchurl {
      url = "https://download.argon40.com/scripts/argonregister.py";
      hash = "sha256-Cs6zOKHlZ6kcLeQxesPFf2dOJF9BIFJaQZX82gFnwEs=";
    })
    (fetchurl {
      url = "https://download.argon40.com/scripts/argonone-irconfig.sh";
      hash = "sha256-JRZq918dQEh5XFT0NJQH0O2ODYvEftdy1lqvoqO3+o8=";
    })
    (fetchurl {
      url = "https://download.argon40.com/scripts/argon-shutdown.sh";
      hash = "sha256-eRfcPCyami78A1iVb0kbrC6g+9FXeSbgfxtRSbbxlJk=";
    })
  ];

  unpackCmd = "cp $curSrc $(stripHash $curSrc)";
  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    bash
  ];

  buildInputs = [
    bash
    python
  ];

  installPhase = ''
    runHook preInstall

    install -m 0755 -D ./argononed.py $out/lib/argononed.py
    install -m 0755 -D ./argonpowerbutton-libgpiod.py $out/lib/argonpowerbutton.py
    install -m 0755 -D ./argonsysinfo.py $out/lib/argonsysinfo.py
    install -m 0755 -D ./argonregister.py $out/lib/argonregister.py
    install -m 0755 -D ./argonone-irconfig.sh $out/lib/argonone-ir
    install -m 0755 -D ./argon-shutdown.sh $out/lib/systemd/system-shutdown/argon-shutdown.sh

    while IFS= LC_ALL=C read -r -d "" -u 9 file; do
      if [ -x "$file" ] && [ ! -L "$file" ]; then
        sed -E -i \
          -e 's%/etc/argon\b%/@out@/lib%' \
          -e 's%pythonbin=.*%pythonbin=${python}/bin/python3%' \
          "$file"

        substituteAllInPlace "$file"
      fi
    done 9< <( find $out -type f -exec printf '%s\0' {} + )

    mkdir -p $out/bin

    ln -s $out/lib/argononed.py $out/bin/argononed

    ln -s ${scripts} $out/lib/scripts

    runHook postInstall
  '';
})
