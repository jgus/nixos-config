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
      ./plex.nix

      ./offsite-jarvis.nix
      ./offsite-gustafson-nas.nix
    ];
}
