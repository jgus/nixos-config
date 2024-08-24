{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  user = "josh";
  group = "users";
in
{
  imports = [(homelabService {
    name = "syncthing";
    requires = [ "home.mount" "nas.mount" ];
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
        "/nas/photos:/shares/Photos"
        "/nas/software/Tools:/shares/Tools"
        "/nas/media/Comics:/shares/Comics"
        "/nas/media/Music:/shares/Music"
      ];
    };
  })];
}
