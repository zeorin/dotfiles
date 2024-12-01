{ lib, pkgs, ... }:

{
  nixpkgs.allowUnfreePackages = [ "mfcj2340dwpdrv" ];
  nixpkgs.overlays = [
    (final: prev: {
      mfcj2340dw =
        let
          model = "mfcj2340dw";
          arches = [
            "x86_64"
            "i686"
          ];
          udev = final.stdenv.mkDerivation (finalAttrs: {
            pname = "brother-udev-rule-type1";
            version = "1.0.2-0";
            src = final.fetchurl {
              url = "https://download.brother.com/welcome/dlf006654/brother-udev-rule-type1-${finalAttrs.version}.all.deb";
              hash = "sha256-gqoXui4zHeH8s08Kg50nubGTrGgNl0IlConliKa9ViA=";
            };
            nativeBuildInputs = with final; [ dpkg ];
            unpackPhase = "dpkg-deb -x $src $out";
            dontBuild = true;
            installPhase = ''
              runHook preInstall

              # remove deprecated SYSFS udev rule
              sed -i -e '/^SYSFS/d' \
                $out/opt/brother/scanner/udev-rules/type1/NN-brother-mfp-type1.rules

              mkdir -p $out/lib/udev/rules.d
              ln -s $out/opt/brother/scanner/udev-rules/type1/NN-brother-mfp-type1.rules \
                $out/lib/udev/rules.d/99-brother-mfp-type1.rules

              runHook postInstall
            '';
          });
        in
        final.stdenv.mkDerivation (finalAttrs: {
          pname = "${model}pdrv";
          version = "3.5.0-1";
          src = final.fetchurl {
            url = "https://download.brother.com/welcome/dlf105453/${model}pdrv-${finalAttrs.version}.i386.deb";
            hash = "sha256-m6ixkKU7Stk6MvdCT8K8drhhTI7kaw0p4Q0KaiT58+w=";
          };
          nativeBuildInputs = with final; [
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
            '') (builtins.filter (arch: arch != final.stdenv.hostPlatform.linuxArch) arches)
            + ''
              patchelf --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
                    $dir/lpd/${final.stdenv.hostPlatform.linuxArch}/br${model}filter
              patchelf --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
                    $dir/lpd/${final.stdenv.hostPlatform.linuxArch}/brprintconf_${model}

              ln -s \
                "$dir/lpd/${final.stdenv.hostPlatform.linuxArch}/"* \
                "$dir/lpd/"

              wrapProgram $dir/inf/setupPrintcapij \
                --prefix PATH : ${lib.makeBinPath [ pkgs.coreutils ]}

              substituteInPlace $dir/lpd/filter_${model} \
                --replace "/usr/bin/perl" "${final.perl}/bin/perl" \
                --replace "PRINTER =~" "PRINTER = \"${model}\"; #" \
                --replace "BR_PRT_PATH =~" "BR_PRT_PATH = \"$dir/\"; #" \
                --replace '`which gs`' '"${final.ghostscript}/bin/gs"'
              wrapProgram $dir/lpd/filter_${model} \
                --prefix PATH : ${
                  lib.makeBinPath (
                    with final;
                    [
                      coreutils
                      file
                      gnugrep
                      gnused
                    ]
                  )
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
                --replace "/usr/bin/perl" "${final.perl}/bin/perl" \
                --replace "basedir =~" "basedir = \"$dir/\"; #" \
                --replace "PRINTER =~" "PRINTER = \"${model}\"; #"
              wrapProgram $dir/cupswrapper/brother_lpdwrapper_${model} \
                --prefix PATH : ${
                  lib.makeBinPath (
                    with final;
                    [
                      coreutils
                      gnugrep
                      gnused
                    ]
                  )
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
        });
    })
  ];

  services.printing.logLevel = "debug";
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [ mfcj2340dw ];
  # Printer sharing
  services.printing.listenAddresses = [ "*:631" ];
  # this gives access to anyone on the interface you might want to limit it see the official documentation
  services.printing.allowFrom = [ "all" ];
  services.printing.browsing = true;
  services.printing.defaultShared = true; # If you want
  services.printing.openFirewall = true;
  services.samba.package = pkgs.sambaFull;
  services.samba.openFirewall = true;
  services.samba.extraConfig = ''
    load printers = yes
    printing = cups
    printcap name = cups
  '';
  services.samba.shares = {
    printers = {
      "comment" = "All Printers";
      "path" = "/var/spool/samba";
      "public" = "yes";
      "browseable" = "yes";
      # to allow user 'guest account' to print.
      "guest ok" = "yes";
      "writable" = "no";
      "printable" = "yes";
      "create mode" = 700;
    };
  };
  systemd.tmpfiles.rules = [ "d /var/spool/samba 1777 root root -" ];

  hardware.printers.ensureDefaultPrinter = "Brother-MFC-J2430DW";
  hardware.printers.ensurePrinters = [
    {
      name = "Brother-MFC-J2430DW";
      description = "Brother MFC-J2430DW";
      location = "Xandor's Office";
      deviceUri = "usb://Brother/MFC-J2340DW?serial=E81715C4H788972";
      model = "brother_mfcj2340dw_printer_en.ppd";
    }
  ];
}
