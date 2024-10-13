{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  gitUpdater,
}:

stdenvNoCC.mkDerivation {
  pname = "done";
  version = "1.19.2";

  src = fetchFromGitHub {
    owner = "franciscolourenco";
    repo = "done";
    rev = "1.19.2";
    hash = "sha256-VSCYsGjNPSFIZSdLrkc7TU7qyPVm8UupOoav5UqXPMk=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    cp -R $src $out

    runHook postInstall
  '';

  passthru.updateScript = gitUpdater { };

  meta = {
    homepage = "https://github.com/franciscolourenco/done";
    description = "A fish-shell package to automatically receive notifications when long processes finish.";
    longDescription = ''
      Just go on with your normal life. You will get a notification when a
      process takes more than 5 seconds finish, and the terminal window not in
      the foreground.
    '';
    license = with lib.licenses; [ mit ];
    maintainers = with lib.maintainers; [ zeorin ];
    platforms = lib.platforms.all;
  };
}
