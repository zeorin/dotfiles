{
  lib,
  writeShellApplication,
  sqlite,
  getoptions,
  unstable,
}:

let
  pname = "newpipelist";
  version = "0.1";

in
writeShellApplication rec {
  name = "${pname}-${version}";
  text = unstable.replaceVars ./newpipelist.sh { inherit version; };
  runtimeInputs = [
    sqlite
    getoptions
  ];
}
