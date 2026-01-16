let
  user = "josh";
  group = "media";
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
      WEBUI_PORT = "8080";
      TORRENTING_PORT = "6881";
    };
    ports = [
      "8080"
      "6881"
      "6881/udp"
    ];
    configVolume = "/config";
    volumes = [
      "/storage/scratch/torrent:/torrent"
    ];
  };
}
