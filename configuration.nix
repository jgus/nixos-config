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
      #./clamav.nix # needs .secrets/gmail-password.nix
    ]
    ++ (if machine.zfs then [ ./zfs.nix ] else [])
    ++ machine.imports;
}
