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

      #./pihole.nix
      ./ddclient.nix
      ./wireguard.nix
      ./landing.nix
      ./samba.nix
      ./syncthing.nix
      ./www.nix
      ./ntp.nix
      ./plex.nix
      ./minecraft.nix
      ./transmission.nix
      ./sabnzbd.nix
      ./prowlarr.nix
      ./lidarr.nix
      ./radarr.nix
      ./sonarr.nix

      ./libvirt.nix
      ./vm-vm1.nix

      ./offsite-sm1.nix
      ./offsite-homeassistant.nix
      #./offsite-gustafson-nas.nix
      #./sync-to-cloud.nix

      ./python.nix
    ];
}
