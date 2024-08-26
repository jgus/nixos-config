{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  user = "plex";
  group = "plex";
in
{
  imports = [(homelabService {
    name = "plex";
    requires = [ "storage-media.mount" "storage-photos.mount" ];
    docker = {
      image = "lscr.io/linuxserver/plex";
      environment = {
        PUID = toString config.users.users.${user}.uid;
        PGID = toString config.users.groups.${group}.gid;
        TZ = config.time.timeZone;
        VERSION = "latest";
      };
      configVolume = "/config";
      volumes = [
        "/storage/media:/media"
        "/storage/photos:/shares/photos"
      ];
      extraOptions = [
        "--gpus=all"
        "--device=/dev/dri:/dev/dri"
        "--tmpfs=/tmp"
      ];
    };
  })];
}
