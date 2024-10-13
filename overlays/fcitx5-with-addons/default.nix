{ ... }:

final: prev: {
  fcitx5-with-addons = prev.fcitx5-with-addons.overrideAttrs (oldAttrs: {
    postBuild = ''
      ${oldAttrs.postBuild or ""}
      # Don't install bundled phrases
      rm $out/share/fcitx5/data/quickphrase.d/*.mb
      # Don't install desktop files
      desktop=share/applications/org.fcitx.Fcitx5.desktop
      autostart=etc/xdg/autostart/org.fcitx.Fcitx5.desktop
      rm $out/$autostart
      mv $out/$desktop $out/$autostart
      rm -rf $out/share/applications
    '';
  });
}
