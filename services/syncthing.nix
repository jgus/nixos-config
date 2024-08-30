let
  user = "josh";
  group = "users";
in
{ config, ... }:
{
  requires = [ "home.mount" "storage-media.mount" "storage-photos.mount" "storage-software.mount" ];
  docker = {
    image = "lscr.io/linuxserver/syncthing";
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
      UMASK_SET = "002";
    };
    ports = [
      "8384"
      "22000"
      "21027/udp"
    ];
    configVolume = "/config";
    volumes = [
      "/home/${user}/sync:/shares/Sync"
      "/storage/photos:/shares/Photos"
      "/storage/software/Tools:/shares/Tools"
      "/storage/media/Comics:/shares/Comics"
      "/storage/media/Music:/shares/Music"
    ];
  };
}
