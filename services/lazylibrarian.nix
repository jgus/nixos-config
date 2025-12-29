let
  user = "josh";
  group = "plex";
in
{ config, ... }:
{
  requires = [ "storage-media.mount" ];
  container = {
    pullImage = {
      imageName = "lscr.io/linuxserver/lazylibrarian";
      imageDigest = "sha256:a17cdc2d8042ab1546c158f9f8d1d1fccf1ccab9df19a91d4c1e8b529ae8f3f7";
      hash = "sha256-Cw5TvAXqGGoD5Z6UtnmfSG0zC9m5/x7K3jmHS5scHnE=";
      finalImageName = "lscr.io/linuxserver/lazylibrarian";
      finalImageTag = "latest";
    };
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
      DOCKER_MODS = "linuxserver/mods:universal-calibre|linuxserver/mods:lazylibrarian-ffmpeg";
    };
    ports = [ "5299" ];
    configVolume = "/config";
    volumes = [
      "/storage/scratch/torrent:/torrent"
      "/storage/scratch/usenet:/usenet"
      "/storage/media:/media"
    ];
  };
}
