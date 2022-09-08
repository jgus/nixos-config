{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      ./interfaces.nix

      ./common.nix
      ./host.nix
      ./users.nix

      ./nvidia.nix
      ./vscode.nix
      ./zfs.nix
      ./clamav.nix

      ./wireguard.nix
      ./landing.nix
      #./syncthing.nix
      ./www.nix
      ./plex.nix
      ./minecraft.nix

      ./offsite-pihole.nix
      ./offsite-s3k1.nix
      ./offsite-gustafson-nas.nix
    ];
}
