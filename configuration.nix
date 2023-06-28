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

      ./nvidia.nix
      ./vscode.nix
      ./zfs.nix
      ./clamav.nix

      #./pihole.nix
      #./ddclient.nix
      ./landing.nix
      ./samba.nix
      ./syncthing.nix
      ./www.nix
      ./ntp.nix
      ./frigate.nix
      ./plex.nix
      ./transmission.nix
      ./sabnzbd.nix
      ./prowlarr.nix
      ./lidarr.nix
      ./radarr.nix
      ./sonarr.nix
      ./mylar.nix
      ./komga.nix
      ./minecraft.nix

#      ./libvirt.nix
#      ./vm-vm1.nix

#      ./offsite-josh-ws.nix
#      ./offsite-homeassistant.nix
      ./offsite-gustafson-nas.nix
      # ./sync-to-cloud.nix

      ./python.nix
    ];
}
