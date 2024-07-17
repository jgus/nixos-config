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

      ./nvidia.nix
      ./vscode.nix
      ./clamav.nix

      #./pihole.nix
      #./ddclient.nix
      ./samba.nix
      ./landing.nix
      ./syncthing.nix
      ./www.nix
      ./ntp.nix
      ./mosquitto.nix
      ./zigbee2mqtt.nix
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
      ./vm-vm1.nix

      #      ./offsite-josh-ws.nix
      #      ./offsite-homeassistant.nix
      ./offsite-gustafson-nas.nix
      # ./sync-to-cloud.nix

      ./userbox.nix

      ./python.nix
    ]
    ++ (if machine.zfs then [ ./zfs.nix ] else [])
    ++ machine.imports;
}
