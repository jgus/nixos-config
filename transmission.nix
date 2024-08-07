{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  image = "haugene/transmission-openvpn";
in
{
  imports = [ ./docker.nix ];

  networking.firewall = {
    allowedTCPPorts = [ 9091 51413 ];
    allowedUDPPorts = [ 9091 51413 ];
  };

  virtualisation.oci-containers.containers.transmission = {
    image = "${image}";
    autoStart = true;
    extraOptions = [
      "--cap-add=NET_ADMIN"
    ];
    environmentFiles = [
      .secrets/privadovpn.env
    ];
    environment = {
      PUID = "${toString config.users.users.josh.uid}";
      PGID = "${toString config.users.groups.plex.gid}";
      TZ = "${config.time.timeZone}";
      OPENVPN_PROVIDER = "PRIVADO";
      LOCAL_NETWORK = "172.22.0.0/16,192.168.2.0/24";
      TRANSMISSION_DOWNLOAD_DIR = "/peer/Complete";
      TRANSMISSION_INCOMPLETE_DIR = "/peer/Incomplete";
      TRANSMISSION_INCOMPLETE_DIR_ENABLED = "true";
      TRANSMISSION_WATCH_DIR = "/peer/Watch";
      TRANSMISSION_WATCH_DIR_ENABLED = "true";
      TRANSMISSION_DOWNLOAD_QUEUE_ENABLED = "false";
      TRANSMISSION_BLOCKLIST_ENABLED = "true";
      TRANSMISSION_BLOCKLIST_URL = "https://github.com/Naunter/BT_BlockLists/raw/master/bt_blocklists.gz";
    };
    ports = [
      "9091:9091"
      "51413:51413"
    ];
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
      "/var/lib/transmission:/config"
      "/nas/scratch/peer:/peer"
    ];
  };

  systemd = {
    services = docker-services {
      name = "transmission";
      image = image;
      setup-script = ''
        if ! zfs list r/varlib/transmission >/dev/null 2>&1
        then
          zfs create r/varlib/transmission
          chown josh:plex /var/lib/transmission
          rsync -arPx --delete /nas/backup/varlib/transmission/ /var/lib/transmission/ || true
        fi
      '';
      backup-script = ''
        mkdir -p /nas/backup/varlib/transmission
        rsync -arPx --delete /var/lib/transmission/ /nas/backup/varlib/transmission/
      '';
    };
  };
}
