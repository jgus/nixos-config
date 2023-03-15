{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      ./interfaces.nix

      ./common.nix
      ./x86.nix
      ./host.nix
      ./users.nix

      ./backup-gateway-client.nix
      ./dyndns.nix
      ./plex.nix
      ./samba.nix
      ./vscode.nix
      ./zfs.nix

      ./clamav.nix
    ];
}
