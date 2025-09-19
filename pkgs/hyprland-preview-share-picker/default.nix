{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  gdk-pixbuf,
  gobject-introspection,
  graphene,
  gtk4,
  gtk4-layer-shell,
  hyprland-protocols,
  pango,
  nix-update-script,
}:

rustPlatform.buildRustPackage rec {
  pname = "hyprland-preview-share-picker";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "WhySoBad";
    repo = "hyprland-preview-share-picker";
    rev = "v${version}";
    hash = "sha256-LOHl7zCxTIDqHIZy8B/RZ76Phz/BKcdrNR4QhQkrcJA=";
    # fetchSubmodules = true;
  };

  cargoHash = "sha256-AqX9jKj7JLEx1SLefyaWYGbRdk0c3H/NDTIsZy6B6hY=";

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    gdk-pixbuf
    gobject-introspection
    graphene
    gtk4
    gtk4-layer-shell
    hyprland-protocols
    pango
  ];

  preBuild = ''
    cp -r ${hyprland-protocols}/share/hyprland-protocols/protocols lib/hyprland-protocols/
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "An alternative share picker for hyprland with window and monitor previews written in rust";
    homepage = "https://github.com/WhySoBad/hyprland-preview-share-picker";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
