# This file defines overlays
{ inputs, ... }: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _: import ../pkgs { pkgs = final; };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev:
    let
      inherit (final) callPackage lib;
      mkUnwrappedFirefox = pkg:
        { binaryName }:
        pkg.override (oldArgs: {
          inherit binaryName;
          extraConfigureFlags = [ "--with-app-name=${binaryName}" ];
          meta = oldArgs.meta // { mainProgram = binaryName; };
        });
    in {
      firefoxPackages = prev.firefoxPackages // (lib.attrsets.recurseIntoAttrs
        (callPackage ({ stdenv, lib, fetchurl, fetchpatch, nixosTests
          , buildMozillaMach }: {
            firefox-beta = buildMozillaMach rec {
              pname = "firefox-beta";
              version = "121.0b5";
              binaryName = "firefox-beta";
              applicationName = "Mozilla Firefox Beta";
              src = fetchurl {
                url =
                  "mirror://mozilla/firefox/releases/${version}/source/firefox-${version}.source.tar.xz";
                sha512 =
                  "1c9d2e8fe32687e95af5cf335ef219e70847977568ca636a322c2804f6408d054236df4196e03fc666ac3245ca4a3a9785caf56e1d928a1850f4b34ab5237f8c";
              };

              extraConfigureFlags = [ "--with-app-name=${binaryName}" ];

              meta = {
                changelog = "https://www.mozilla.org/en-US/firefox/${
                    lib.versions.majorMinor version
                  }beta/releasenotes/";
                description =
                  "A web browser built from Firefox Beta Release source tree";
                homepage = "http://www.mozilla.com/en-US/firefox/";
                maintainers = with lib.maintainers; [ jopejoe1 ];
                platforms = lib.platforms.unix;
                badPlatforms = lib.platforms.darwin;
                broken =
                  stdenv.buildPlatform.is32bit; # since Firefox 60, build on 32-bit platforms fails with "out of memory".
                # not in `badPlatforms` because cross-compilation on 64-bit machine might work.
                maxSilent =
                  14400; # 4h, double the default of 7200s (c.f. #129212, #129115)
                license = lib.licenses.mpl20;
                mainProgram = binaryName;
              };
              tests = [ nixosTests.firefox-beta ];
            };

            firefox-devedition = buildMozillaMach rec {
              pname = "firefox-devedition";
              version = "121.0b5";
              binaryName = "firefox-developer-edition";
              applicationName = "Mozilla Firefox Developer Edition";
              requireSigning = false;
              branding = "browser/branding/aurora";
              src = fetchurl {
                url =
                  "mirror://mozilla/devedition/releases/${version}/source/firefox-${version}.source.tar.xz";
                sha512 =
                  "cf23b18abece88f4cee418892791a8a4076ccc14cfe0f1d58f9284ec72f109e44a5397a88b4350f963a3e02e53dd91d7b777c36debd9a3621081499519659f6e";
              };

              extraConfigureFlags = [ "--with-app-name=${binaryName}" ];

              meta = {
                changelog = "https://www.mozilla.org/en-US/firefox/${
                    lib.versions.majorMinor version
                  }beta/releasenotes/";
                description =
                  "A web browser built from Firefox Developer Edition source tree";
                homepage = "http://www.mozilla.com/en-US/firefox/";
                maintainers = with lib.maintainers; [ jopejoe1 ];
                platforms = lib.platforms.unix;
                badPlatforms = lib.platforms.darwin;
                broken =
                  stdenv.buildPlatform.is32bit; # since Firefox 60, build on 32-bit platforms fails with "out of memory".
                # not in `badPlatforms` because cross-compilation on 64-bit machine might work.
                maxSilent =
                  14400; # 4h, double the default of 7200s (c.f. #129212, #129115)
                license = lib.licenses.mpl20;
                mainProgram = binaryName;
              };
              tests = [ nixosTests.firefox-devedition ];
            };

            firefox-esr-115 = buildMozillaMach rec {
              pname = "firefox-esr-115";
              version = "115.5.0esr";
              binaryName = "firefox-esr";
              applicationName = "Mozilla Firefox ESR";
              src = fetchurl {
                url =
                  "mirror://mozilla/firefox/releases/${version}/source/firefox-${version}.source.tar.xz";
                sha512 =
                  "5ee722884cd545cf5146f414526b4547286625f4f5996a409d7f64f115633fb7eb74d202e82f175fd5b2d24cce88deee70020fcb284055fcdea3d39da182074e";
              };

              extraConfigureFlags = [ "--with-app-name=${binaryName}" ];

              meta = {
                changelog = "https://www.mozilla.org/en-US/firefox/${
                    lib.removeSuffix "esr" version
                  }/releasenotes/";
                description =
                  "A web browser built from Firefox Extended Support Release source tree";
                homepage = "http://www.mozilla.com/en-US/firefox/";
                maintainers = with lib.maintainers; [ hexa ];
                platforms = lib.platforms.unix;
                badPlatforms = lib.platforms.darwin;
                broken =
                  stdenv.buildPlatform.is32bit; # since Firefox 60, build on 32-bit platforms fails with "out of memory".
                # not in `badPlatforms` because cross-compilation on 64-bit machine might work.
                license = lib.licenses.mpl20;
                mainProgram = binaryName;
              };
              tests = [ nixosTests.firefox-esr-115 ];
            };
          }) { }));
      firefox-beta = prev.firefox-beta.override { nameSuffix = ""; };
      firefox-devedition =
        prev.firefox-devedition.override { nameSuffix = ""; };
      firefox-esr-115 = prev.firefox-esr-115.override { nameSuffix = ""; };
    };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final) system config overlays;
    };
  };
}
