let
  user = "josh";
  group = "media";
in
{ config, ... }:
{
  homelab.services.lazylibrarian = {
    requires = [ "storage-media.mount" ];
    container = {
      pullImage = import ../../images/lazylibrarian.nix;
      readOnly = false;
      environment = {
        PUID = toString config.users.users.${user}.uid;
        PGID = toString config.users.groups.${group}.gid;
        DOCKER_MODS = "linuxserver/mods:universal-calibre|linuxserver/mods:lazylibrarian-ffmpeg";
      };
      configVolume = "/config";
      volumes = [
        "/storage/scratch/torrent:/torrent"
        "/storage/scratch/usenet:/usenet"
        "/storage/media:/media"
      ];
      ports = [ "5299" ];
    };
  };
}
