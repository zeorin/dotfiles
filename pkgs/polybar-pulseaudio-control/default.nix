{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
  bash,
  pulseaudio,
  libnotify,
  gnugrep,
  gawk,
  gnused,
  coreutils,
  makeWrapper,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "polybar-pulseaudio-control";
  version = "3.1.1";

  src = fetchFromGitHub {
    owner = "marioortizmanero";
    repo = "polybar-pulseaudio-control";
    rev = "v${finalAttrs.version}";
    hash = "sha256-egCBCnhnmHHKFeDkpaF9Upv/oZ0K3XGyutnp4slq9Vc=";
  };

  buildInputs = [
    bash
    pulseaudio
    libnotify
    gnugrep
    gawk
    gnused
    coreutils
  ];

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    makeWrapper $src/pulseaudio-control.bash $out/bin/pulseaudio-control \
      --prefix PATH : ${
        lib.makeBinPath [
          bash
          pulseaudio
          libnotify
          gnugrep
          gawk
          gnused
          coreutils
        ]
      }
  '';

  passthru.updateScript = nix-update-script { };
})
