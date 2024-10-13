{ ... }:

final: prev: {
  mpvScripts = prev.mpvScripts.overrideScope (
    sfinal: sprev: {
      uosc = sprev.uosc.overrideAttrs (
        finalAttrs: oldAttrs: {
          version = "5.5.0";
          src = final.fetchFromGitHub {
            owner = "tomasklaen";
            repo = "uosc";
            rev = finalAttrs.version;
            hash = "sha256-WFsqA5kGefQmvihLUuQBfMmKoUHiO7ofxpwISRygRm4=";
          };
        }
      );
    }
  );
}
