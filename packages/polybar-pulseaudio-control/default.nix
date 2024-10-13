{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  bash,
  pulseaudio,
  libnotify,
  gnugrep,
  gawk,
  gnused,
  coreutils,
  unstableGitUpdater,
}:

stdenvNoCC.mkDerivation {
  pname = "polybar-pulseaudio-control";
  version = "unstable-2024-10-19";

  src = fetchFromGitHub {
    owner = "marioortizmanero";
    repo = "polybar-pulseaudio-control";
    rev = "ed03a1b85dd0e92f85bc7446b78e010b36be4606";
    hash = "sha256-psaZQBC9LMdmaXWIHytfP4CjiduRm4ObEWCgFDGehWg=";
  };

  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [
    bash
    pulseaudio
    libnotify
    gnugrep
    gawk
    gnused
    coreutils
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp pulseaudio-control $out/bin/pulseaudio-control
    wrapProgram $out/bin/pulseaudio-control \
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

    runHook postInstall
  '';

  passthru.updateScript = unstableGitUpdater { };

  meta = {
    homepage = "https://github.com/marioortizmanero/polybar-pulseaudio-control";
    description = "A feature-full Polybar module to control PulseAudio";
    license = with lib.licenses; [ mit ];
    maintainers = with lib.maintainers; [ zeorin ];
    platforms = lib.platforms.all;
  };
}
