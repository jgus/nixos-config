{ config, pkgs, ... }:

let
  machine = import ./machine.nix;
in
{
  imports =
    [ # Include the results of the hardware scan.
      (if (machine.arch == "rpi") then ./hardware-configuration-pi.nix else ./hardware-configuration.nix)
      ./interfaces.nix
      ./common.nix
      ./${machine.arch}.nix
      ./host.nix
      ./users.nix
      ./vscode.nix

      ./pihole.nix
      ./ntp.nix
      ./landing.nix
      ./nas.nix
      ./syncthing.nix
      ./mosquitto.nix
      ./plex.nix
    ]
    ++ (if machine.nvidia then [ ./nvidia.nix ] else [])
    ++ (if machine.zfs then [ ./zfs.nix ] else [])
    ++ (if machine.clamav then [ ./clamav.nix ] else [])
    ++ (if machine.python then [ ./python.nix ] else [])
    ++ machine.imports;
}
