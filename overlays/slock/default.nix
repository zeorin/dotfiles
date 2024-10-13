{ ... }:

final: prev: {
  slock = prev.slock.overrideAttrs (oldAttrs: {
    preBuild = "cp ${./config.h} config.h";
    patches = (oldAttrs.patches or [ ]) ++ [ ./patches.diff ];
    buildInputs = (oldAttrs.buildInputs or [ ]) ++ [ final.imlib2 ];
  });
}
