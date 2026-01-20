let
  user = "josh";
  group = "media";
in
{ config, ... }:
{
  requires = [ "storage-media.mount" ];
  container = {
    readOnly = false;
    pullImage = import ../images/calibre-web.nix;
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      DOCKER_MODS = "linuxserver/mods:universal-calibre";
    };
    ports = [ "8083" ];
    configVolume = "/config";
    volumes = [
      "/storage/media:/media"
    ];
  };
}
