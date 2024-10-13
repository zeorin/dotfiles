{
  lib,
  perlPackages,
  fetchurl,
  pass,
  fetchFromGitHub,
}:

let
  perl-pass-otp = perlPackages.buildPerlPackage {
    pname = "Pass-OTP";
    version = "1.5";
    src = fetchurl {
      url = "mirror://cpan/authors/id/J/JB/JBAIER/Pass-OTP-1.5.tar.gz";
      hash = "sha256-GujxwmvfSXMAsX7LRiI7Q9YgsolIToeFRYEVAYFJeaM=";
    };
    buildInputs = with perlPackages; [
      ConvertBase32
      DigestHMAC
      DigestSHA3
      MathBigInt
    ];
    doCheck = false;
  };

in
pass.extensions.pass-otp.overrideAttrs (
  finalAttrs: oldAttrs: {
    version = "1.2.0.r29.a364d2a";
    src = fetchFromGitHub {
      owner = "tadfisher";
      repo = "pass-otp";
      rev = "a364d2a71ad24158a009c266102ce0d91149de67";
      hash = "sha256-q9m6vkn+IQyR/ZhtzvZii4uMZm1XVeBjJqlScaPsL34=";
    };
    buildInputs = [ perl-pass-otp ];
    patchPhase = ''
      sed -i -e 's|OATH=\$(which oathtool)|OATH=${perl-pass-otp}/bin/oathtool|' otp.bash
      sed -i -e 's|OTPTOOL=\$(which otptool)|OTPTOOL=${perl-pass-otp}/bin/otptool|' otp.bash
    '';
  }
)
