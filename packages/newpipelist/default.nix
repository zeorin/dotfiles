{
  lib,
  writeShellApplication,
  sqlite,
  getoptions,
  unstable,
}:

writeShellApplication rec {
  pname = "newpipelist";
  version = "0.1";
  text = unstable.replaceVars ./newpipelist.sh { inherit version; };
  runtimeInputs = [
    sqlite
    getoptions
  ];
}
