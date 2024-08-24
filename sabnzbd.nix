{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  user = "josh";
  group = "plex";
in
{
  imports = [(homelabService {
    name = "sabnzbd";
    requires = [ "nas.mount" ];
    docker = {
      image = "lscr.io/linuxserver/sabnzbd";
      environment = {
        PUID = toString config.users.users.${user}.uid;
        PGID = toString config.users.groups.${group}.gid;
        TZ = config.time.timeZone;
      };
      ports = [
        "8080"
      ];
      configVolume = "/config";
      volumes = [
        "/nas/scratch/usenet:/config/Downloads"
      ];
    };
  })];
}
