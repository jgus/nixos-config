{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  user = "josh";
  group = "plex";
in
{
  imports = [(homelabService {
    name = "transmission";
    requires = [ "nas.mount" ];
    docker = {
      image = "haugene/transmission-openvpn";
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
      configVolume = "/config";
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "/nas/scratch/peer:/peer"
      ];
      extraOptions = [
        "--cap-add=NET_ADMIN"
      ];
    };
  })];
}
