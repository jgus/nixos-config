{ ... }:

let
  machine = import ./machine.nix;
in
{
  time.timeZone = "America/Denver";

  networking = {
    hostName = machine.hostName;
    hostId = machine.hostId;
  };
}
