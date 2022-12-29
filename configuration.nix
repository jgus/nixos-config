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

      ./offsite-c1.nix
      ./offsite-gustafson-nas.nix
    ];
}
