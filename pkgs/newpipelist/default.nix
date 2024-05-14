{ lib, writeShellApplication, sqlite, getoptions }:

writeShellApplication {
  name = "newpipelist";
  text = lib.strings.readFile ./newpipelist.sh;
  runtimeInputs = [ sqlite getoptions ];
}
