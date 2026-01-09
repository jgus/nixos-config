{ pkgs, ... }:
let
  myLib = import ./my-lib.nix { inherit pkgs; };
  machine = import ./machine.nix;
in
{
  imports = [
    ./machine/${machine.hostName}/hardware-configuration.nix
    ./common.nix
    ./${machine.arch}.nix
    ./host.nix
    ./users.nix
    ./sops.nix
    ./vscode.nix
    ./storage.nix
    ./backup.nix
    ./services.nix
    ./status2mqtt.nix
    ./systemctl-mqtt.nix
  ]
  ++ (if machine.nvidia then [ ./nvidia.nix ] else [ ])
  ++ (if machine.zfs then [ ./zfs.nix ] else [ ])
  ++ (if machine.clamav then [ ./clamav.nix ] else [ ])
  ++ (if machine.python then [ ./python.nix ] else [ ])
  ++ machine.imports;

  _module.args = { inherit myLib; };
}
