{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  user = "plex";
  group = "plex";
in
{
  imports = [(homelabService {
    name = "plex";
    requires = [ "nas.mount" ];
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
        "/nas/media:/media"
        "/nas/photos:/shares/photos"
      ];
      extraOptions = [
        "--gpus=all"
        "--device=/dev/dri:/dev/dri"
        "--tmpfs=/tmp"
      ];
    };
  })];
}
