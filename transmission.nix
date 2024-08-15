{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  service = "transmission";
  user = "josh";
  group = "plex";
  image = "haugene/transmission-openvpn";
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
in
if (machine.hostName != addresses.records."${service}".host) then {} else
{
  imports = [ ./docker.nix ];

  virtualisation.oci-containers.containers."${service}" = {
    image = image;
    autoStart = true;
    extraOptions = (addresses.dockerOptions service) ++ [
      "--cap-add=NET_ADMIN"
    ];
    environmentFiles = [
      .secrets/privadovpn.env
    ];
    environment = {
      PUID = toString config.users.users."${user}".uid;
      PGID = toString config.users.groups."${group}".gid;
      TZ = config.time.timeZone;
      OPENVPN_PROVIDER = "PRIVADO";
      LOCAL_NETWORK = "172.22.0.0/16";
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
      "9091"
      "51413"
    ];
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
      "/var/lib/${service}:/config"
      "/nas/scratch/peer:/peer"
    ];
  };

  systemd = {
    services = docker-services {
      name = service;
      image = image;
      setup-script = ''
        if ! zfs list r/varlib/${service} >/dev/null 2>&1
        then
          zfs create r/varlib/${service}
          chown ${user}:${group} /var/lib/${service}
          rsync -arPx --delete /nas/backup/varlib/${service}/ /var/lib/${service}/ || true
        fi
      '';
      backup-script = ''
        mkdir -p /nas/backup/varlib/${service}
        rsync -arPx --delete /var/lib/${service}/ /nas/backup/varlib/${service}/
      '';
    };
  };
}
