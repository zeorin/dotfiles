{
  lib,
  stdenv,
  fetchurl,
  coreutils,
  perl,
  ghostscript,
  dpkg,
  makeWrapper,
  file,
  gnugrep,
  gnused,
}:

let
  model = "mfcj2340dw";

  arches = [
    "x86_64"
    "i686"
  ];

  udev = stdenv.mkDerivation (finalAttrs: {
    pname = "brother-udev-rule-type1";
    version = "1.0.2-0";
    src = fetchurl {
      url = "https://download.brother.com/welcome/dlf006654/brother-udev-rule-type1-${finalAttrs.version}.all.deb";
      hash = "sha256-gqoXui4zHeH8s08Kg50nubGTrGgNl0IlConliKa9ViA=";
    };
    nativeBuildInputs = [ dpkg ];
    unpackPhase = "dpkg-deb -x $src $out";
    dontBuild = true;
    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/udev/rules.d
      ln -s $out/opt/brother/scanner/udev-rules/type1/NN-brother-mfp-type1.rules \
        $out/lib/udev/rules.d/99-brother-mfp-type1.rules

      runHook postInstall
    '';
  });

in
stdenv.mkDerivation (finalAttrs: {
  pname = "${model}pdrv";
  version = "3.5.0-1";
  src = fetchurl {
    url = "https://download.brother.com/welcome/dlf105453/${model}pdrv-${finalAttrs.version}.i386.deb";
    hash = "sha256-m6ixkKU7Stk6MvdCT8K8drhhTI7kaw0p4Q0KaiT58+w=";
  };
  nativeBuildInputs = [
    dpkg
    makeWrapper
  ];
  unpackPhase = "dpkg-deb -x $src .";
  patches = [
    # The brother lpdwrapper uses a temporary file to convey the printer settings.
    # The original settings file will be copied with "400" permissions and the "brprintconflsr3"
    # binary cannot alter the temporary file later on. This fixes the permissions so the can be modified.
    # Since this is all in briefly in the temporary directory of systemd-cups and not accessible by others,
    # it shouldn't be a security concern.
    ./brother_lpdwrapper.patch
  ];
  dontBuild = true;
  installPhase =
    ''
      runHook preInstall

      mkdir -p $out
      cp -ar opt $out/opt

      dir="$out/opt/brother/Printers/${model}"

      mkdir -p $out/etc/opt/brother/Printers/${model}

      ln -s $dir/inf $out/etc/opt/brother/Printers/${model}/inf

      # delete unnecessary files for the current architecture
    ''
    + lib.concatMapStrings (arch: ''
      echo Deleting files for ${arch}
      rm -r "$dir/lpd/${arch}"
    '') (builtins.filter (arch: arch != stdenv.hostPlatform.linuxArch) arches)
    + ''
      patchelf --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
            $dir/lpd/${stdenv.hostPlatform.linuxArch}/br${model}filter
      patchelf --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
            $dir/lpd/${stdenv.hostPlatform.linuxArch}/brprintconf_${model}

      ln -s \
        "$dir/lpd/${stdenv.hostPlatform.linuxArch}/"* \
        "$dir/lpd/"

      wrapProgram $dir/inf/setupPrintcapij \
        --prefix PATH : ${lib.makeBinPath [ coreutils ]}

      substituteInPlace $dir/lpd/filter_${model} \
        --replace "/usr/bin/perl" "${perl}/bin/perl" \
        --replace "PRINTER =~" "PRINTER = \"${model}\"; #" \
        --replace "BR_PRT_PATH =~" "BR_PRT_PATH = \"$dir/\"; #" \
        --replace '`which gs`' '"${ghostscript}/bin/gs"'
      wrapProgram $dir/lpd/filter_${model} \
        --prefix PATH : ${
          lib.makeBinPath ([
            coreutils
            file
            gnugrep
            gnused
          ])
        }

      substituteInPlace $dir/cupswrapper/cupswrapper${model} \
        --replace "mkdir -p /usr" ": # mkdir -p /usr" \
        --replace "rm -f " ": # rm -f " \
        --replace "chmod " ": # chmod " \
        --replace "cp " ": # cp " \
        --replace "ln -s " ": # ln -s " \
        --replace '/opt/brother/''${device_model}/''${printer_model}' "$dir" \
        --replace '/''${device_model}' "/Printer" \
        --replace '/usr/lib64' "$out/lib" \
        --replace '/usr/lib' "$out/lib" \
        --replace '/usr/share/ppd/Brother' "$out/share/cups/model" \
        --replace '/usr/share/ppd' "$out/share/cups" \
        --replace '/usr/share/cups/model/Brother' "$out/share/cups/model" \
        --replace '/usr/share/cups/model' "$out/share/cups"

      substituteInPlace $dir/cupswrapper/brother_lpdwrapper_${model} \
        --replace "/usr/bin/perl" "${perl}/bin/perl" \
        --replace "basedir =~" "basedir = \"$dir/\"; #" \
        --replace "PRINTER =~" "PRINTER = \"${model}\"; #"
      wrapProgram $dir/cupswrapper/brother_lpdwrapper_${model} \
        --prefix PATH : ${
          lib.makeBinPath ([
            coreutils
            gnugrep
            gnused
          ])
        }

      mkdir -p $out/lib/cups/filter
      mkdir -p $out/share/cups/model

      ln $dir/cupswrapper/cupswrapper${model} $out/lib/cups/filter
      ln $dir/cupswrapper/brother_lpdwrapper_${model} $out/lib/cups/filter
      ln $dir/cupswrapper/brother_${model}_printer_en.ppd $out/share/cups/model

      mkdir -p $out/lib/udev/rules.d
      ln -s ${udev}/lib/udev/rules.d/99-brother-mfp-type1.rules \
        $out/lib/udev/rules.d/99-brother-mfp-type1.rules

      runHook postInstall
    '';
  meta = {
    description = "Brother ${lib.strings.toUpper model} driver";
    homepage = "http://www.brother.com/";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.unfree;
    platforms = builtins.map (arch: "${arch}-linux") arches;
    maintainers = [ lib.maintainers.zeorin ];
  };
})