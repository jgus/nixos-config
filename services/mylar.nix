let
  user = "josh";
  group = "plex";
in
{ config, ... }:
{
  requires = [ "storage-media.mount" "storage-scratch.mount" ];
  docker = {
    image = "lscr.io/linuxserver/mylar3";
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
    };
    ports = [
      "8090"
    ];
    configVolume = "/config";
    volumes = [
      "/storage/media/Comics:/comics"
      "/storage/media/Comics.import:/import"
      "/storage/scratch/torrent:/torrent"
      "/storage/scratch/usenet:/usenet"
    ];
    # extraOptions = [
    #   "--tmpfs=/config/mylar/cache"
    # ];
  };
}
