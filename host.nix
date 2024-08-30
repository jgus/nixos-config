let
  machine = import ./machine.nix;
in
{ lib, ... }:
{
  time.timeZone = "America/Denver";

  environment.etc = builtins.listToAttrs
    (lib.lists.flatten (map
      (
        i: [
          {
            name = "ssh/ssh_host_${i}_key";
            value = {
              source = ./.secrets/etc/ssh/ssh_host_${i}_key;
              mode = "0600";
            };
          }
          {
            name = "ssh/ssh_host_${i}_key.pub";
            value = {
              source = ./.secrets/etc/ssh/ssh_host_${i}_key.pub;
              mode = "0644";
            };
          }
        ]
      ) [ "ecdsa" "ed25519" "rsa" ])) // { };

  networking = {
    hostName = machine.hostName;
    hostId = machine.hostId;
  };
}
