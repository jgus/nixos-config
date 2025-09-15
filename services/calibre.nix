let
  user = "josh";
  group = "plex";
in
{ config, ... }:
{
  requires = [ "storage-media.mount" ];
  docker = {
    image = "lscr.io/linuxserver/calibre-web";
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
