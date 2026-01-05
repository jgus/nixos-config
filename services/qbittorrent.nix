let
  user = "josh";
  group = "plex";
in
{ config, ... }:
{
  requires = [ "storage-scratch.mount" ];
  container = {
    readOnly = false;
    pullImage = import ../images/qbittorrent.nix;
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
      WEBUI_PORT = "80";
      TORRENTING_PORT = "6881";
    };
    ports = [
      "80"
      "6881"
      "6881/udp"
    ];
    configVolume = "/config";
    volumes = [
      "/storage/scratch/torrent:/torrent"
    ];
  };
}
