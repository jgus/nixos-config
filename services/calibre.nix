let
  user = "josh";
  group = "plex";
in
{ config, ... }:
{
  requires = [ "storage-media.mount" ];
  container = {
    pullImage = {
      imageName = "lscr.io/linuxserver/calibre-web";
      imageDigest = "sha256:6ad57f800588623fe598b7c8d4c39b20f9234798987757b67a8e50e7aabf95ff";
      hash = "sha256-9oCWRUGRlSvcnLKmJEkKXHjRrgtGkv2NgZLzNIZuGow=";
      finalImageName = "lscr.io/linuxserver/calibre-web";
      finalImageTag = "latest";
    };
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
      DOCKER_MODS = "linuxserver/mods:universal-calibre";
    };
    ports = [ "8083" ];
    configVolume = "/config";
    volumes = [
      "/storage/media:/media"
    ];
  };
}
