let
  machine = import ./machine.nix;
in
{ config, pkgs, ... }:
{
  imports = [
    ./machine/${machine.hostName}/hardware-configuration.nix
    ./common.nix
    ./${machine.arch}.nix
    ./host.nix
    ./users.nix
    ./vscode.nix
    ./storage.nix
    ./backup.nix
    ./services.nix
    ./backup.nix
    ./status2mqtt.nix
  ]
  ++ (if machine.nvidia then [ ./nvidia.nix ] else [ ])
  ++ (if machine.zfs then [ ./zfs.nix ] else [ ])
  ++ (if machine.clamav then [ ./clamav.nix ] else [ ])
  ++ (if machine.python then [ ./python.nix ] else [ ])
  ++ machine.imports;
}
