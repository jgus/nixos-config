{ config, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
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
      ./samba.nix
      ./landing.nix
      ./syncthing.nix
      ./www.nix
      ./ntp.nix
      ./mosquitto.nix
      #./home-assistant-record.nix
      ./home-assistant.nix
      ./esphome.nix
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

      ./userbox.nix

      ./python.nix
    ];
}
