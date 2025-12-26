{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  perl,
  gnused,
  ghostscript,
  file,
  coreutils,
  gnugrep,
  which,
  util-linux,
  xxd,
  runtimeShell,
}:

let
  arches = [
    "x86_64"
    "i686"
  ];

  runtimeDeps = [
    ghostscript
    file
    gnused
    gnugrep
    coreutils
    which
  ];
in

stdenv.mkDerivation (finalAttrs: {
  pname = "cups-brother-mfcj2340dw";
  version = "3.5.0-1";

  nativeBuildInputs = [
    dpkg
    makeWrapper
    autoPatchelfHook
  ];
  buildInputs = [ perl ];

  dontUnpack = true;

  src = fetchurl {
    url = "https://download.brother.com/welcome/dlf105453/mfcj2340dwpdrv-${finalAttrs.version}.i386.deb";
    hash = "sha256-m6ixkKU7Stk6MvdCT8K8drhhTI7kaw0p4Q0KaiT58+w=";
  };

  brprintconf_mfcj2340dw_script = ''
    #!${runtimeShell}
    cd $(mktemp -d)
    ln -s @out@/opt/brother/Printers/mfcj2340dw/lpd/${stdenv.hostPlatform.linuxArch}/.brprintconf_mfcj2340dw-wrapped brprintconf_mfcj2340dw
    ln -s @out@/opt/brother/Printers/mfcj2340dw/inf/brmfcj2340dwfunc
    ln -s @out@/opt/brother/Printers/mfcj2340dw/inf/brmfcj2340dwrc
    ./brprintconf_mfcj2340dw "$@"
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    dpkg-deb -x $src $out

    # delete unnecessary files for the current architecture
  ''
  + lib.concatMapStrings (arch: ''
    echo Deleting files for ${arch}
    rm -r "$out/opt/brother/Printers/mfcj2340dw/lpd/${arch}"
  '') (builtins.filter (arch: arch != stdenv.hostPlatform.linuxArch) arches)
  + ''

    # The executable "brprintconf_mfcj2340dw" binary is looking for "/opt/brother/Printers/%s/inf/br%sfunc" and "/opt/brother/Printers/%s/inf/br%src".
    # Whereby, %s is printf(3) string substitution for stdin's arg0 (the command's own filename) from the 10th char forwards, as a runtime dependency.
    # e.g. Say the filename is "0123456789ABCDE", the runtime will be looking for /opt/brother/Printers/ABCDE/inf/brABCDEfunc.
    # Presumably, the binary was designed to be deployed under the filename "printconf_mfcj2340dw", whereby it will search for "/opt/brother/Printers/mfcj2340dw/inf/brmfcj2340dwfunc".
    # For NixOS, we want to change the string to the store path of brmfcj2340dwfunc and brmfcj2340dwrc but we're faced with two complications:
    # 1. Too little room to specify the nix store path. We can't even take advantage of %s by renaming the file to the store path hash since the variable is too short and can't contain the whole hash.
    # 2. The binary needs the directory it's running from to be r/w.
    # What:
    # As such, we strip the path and substitution altogether, leaving only "brmfcj2340dwfunc" and "brmfcj2340dwrc", while filling the leftovers with nulls.
    # Fully null terminating the cstrings is necessary to keep the array the same size and preventing overflows.
    # We then use a shell script to link and execute the binary, func and rc files in a temporary directory.
    # How:
    # In the package, we dump the raw binary as a string of search-able hex values using hexdump. We execute the substitution with sed. We then convert the hex values back to binary form using xxd.
    # We also write a shell script that invoked "mktemp -d" to produce a r/w temporary directory and link what we need in the temporary directory.
    # Result:
    # The user can run brprintconf_mfcj2340dw in the shell.
    ${util-linux}/bin/hexdump -ve '1/1 "%.2X"' $out/opt/brother/Printers/mfcj2340dw/lpd/${stdenv.hostPlatform.linuxArch}/brprintconf_mfcj2340dw | \
    sed 's.2F6F70742F62726F746865722F5072696E746572732F25732F696E662F6272257366756E63.62726d66636a36353130647766756e63000000000000000000000000000000000000000000.' | \
    sed 's.2F6F70742F62726F746865722F5072696E746572732F25732F696E662F627225737263.62726D66636A3635313064777263000000000000000000000000000000000000000000.' | \
    ${xxd}/bin/xxd -r -p > $out/opt/brother/Printers/mfcj2340dw/lpd/${stdenv.hostPlatform.linuxArch}/.brprintconf_mfcj2340dw-wrapped
    chmod +x $out/opt/brother/Printers/mfcj2340dw/lpd/${stdenv.hostPlatform.linuxArch}/.brprintconf_mfcj2340dw-wrapped
    rm $out/opt/brother/Printers/mfcj2340dw/lpd/${stdenv.hostPlatform.linuxArch}/brprintconf_mfcj2340dw

    # executing from current dir. segfaults if it's not r\w.
    echo -n "$brprintconf_mfcj2340dw_script" > $out/opt/brother/Printers/mfcj2340dw/lpd/${stdenv.hostPlatform.linuxArch}/brprintconf_mfcj2340dw
    chmod +x $out/opt/brother/Printers/mfcj2340dw/lpd/${stdenv.hostPlatform.linuxArch}/brprintconf_mfcj2340dw
    substituteInPlace $out/opt/brother/Printers/mfcj2340dw/lpd/${stdenv.hostPlatform.linuxArch}/brprintconf_mfcj2340dw --replace @out@ $out

    # bundled scripts don't understand the arch subdirectories for some reason
    ln -s $out/opt/brother/Printers/mfcj2340dw/lpd/${stdenv.hostPlatform.linuxArch}/brmfcj2340dwfilter \
      $out/opt/brother/Printers/mfcj2340dw/lpd/
    ln -s $out/opt/brother/Printers/mfcj2340dw/lpd/${stdenv.hostPlatform.linuxArch}/brprintconf_mfcj2340dw \
      $out/opt/brother/Printers/mfcj2340dw/lpd/

    # Fix global references and replace auto discovery mechanism with hardcoded values
    substituteInPlace $out/opt/brother/Printers/mfcj2340dw/cupswrapper/brother_lpdwrapper_mfcj2340dw \
      --replace /opt "$out/opt" \
      --replace "my \$basedir =" "my \$basedir = \"$out/opt/brother/Printers/mfcj2340dw/\"; #" \
      --replace "PRINTER =~" "PRINTER = \"mfcj2340dw\"; #"
    substituteInPlace $out/opt/brother/Printers/mfcj2340dw/lpd/filter_mfcj2340dw \
      --replace /opt "$out/opt" \
      --replace "my \$BR_PRT_PATH =" "my \$BR_PRT_PATH = \"$out/opt/brother/Printers/mfcj2340dw/\"; #" \
      --replace "PRINTER =~" "PRINTER = \"mfcj2340dw\"; #"

    # Make sure all executables have the necessary runtime dependencies available
    find "$out" -executable -and -type f | while read file; do
      [[ $file == *.ppd ]] && continue
      wrapProgram "$file" --prefix PATH : "${lib.makeBinPath runtimeDeps}"
    done

    # Symlink filter and ppd into a location where CUPS will discover it
    mkdir -p $out/lib/cups/filter $out/share/cups/model
    ln -s \
      $out/opt/brother/Printers/mfcj2340dw/cupswrapper/brother_lpdwrapper_mfcj2340dw \
      $out/lib/cups/filter/
    ln -s \
      $out/opt/brother/Printers/mfcj2340dw/cupswrapper/brother_mfcj2340dw_printer_en.ppd \
      $out/share/cups/model/

    mkdir -p $out/bin
    ln -s \
      $out/opt/brother/Printers/mfcj2340dw/lpd/brprintconf_mfcj2340dw \
      $out/bin/

    runHook postInstall
  '';

  meta = {
    homepage = "https://www.brother.com/";
    description = "Brother MFC-J2340DW printer driver";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.unfree;
    platforms = map (arch: "${arch}-linux") arches;
    maintainers = [ lib.maintainers.zeorin ];
  };
})
