let
  user = "josh";
  group = "media";
in
{ config, ... }:
{
  homelab.services.qbittorrent = {
    requires = [ "storage-scratch.mount" ];
    container = {
      pullImage = import ../../images/qbittorrent.nix;
      readOnly = false;
      environment = {
        PUID = toString config.users.users.${user}.uid;
        PGID = toString config.users.groups.${group}.gid;
        WEBUI_PORT = "8080";
        TORRENTING_PORT = "6881";
      };
      configVolume = "/config";
      volumes = [
        "/storage/scratch/torrent:/torrent"
      ];
      ports = [
        "8080"
        "6881"
        "6881/udp"
      ];
    };
  };
}
