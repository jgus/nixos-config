{ config, pkgs, ... }:

# smbpasswd -a josh

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      ./interfaces.nix

      ./common.nix
      ./host.nix
      ./users.nix

      #./nvidia.nix
      ./vscode.nix
      ./zfs.nix
      ./clamav.nix

      ./user-plex.nix
      ./user-www.nix
      ./samba.nix
      ./syncthing.nix
      ./transmission.nix
      ./sonarr.nix

      ./offsite-c240m3.nix
    ];
}
