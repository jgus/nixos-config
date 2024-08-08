{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  image = "lscr.io/linuxserver/plex";
  addresses = import ./addresses.nix;
in
{
  imports = [ ./docker.nix ];

  virtualisation.oci-containers.containers.plex = {
    image = "${image}";
    autoStart = true;
    extraOptions = [
      "--network=macvlan"
      "--mac-address=${addresses.services.plex.mac}"
      "--ip=${addresses.services.plex.ip}"
      "--gpus=all"
      "--device=/dev/dri:/dev/dri"
      "--tmpfs=/tmp"
    ];
    environment = {
      PUID = "${toString config.users.users.plex.uid}";
      PGID = "${toString config.users.groups.plex.gid}";
      TZ = "${config.time.timeZone}";
      VERSION = "latest";
    };
    volumes = [
      "/var/lib/plex:/config"
      "/nas/media:/media"
      "/nas/photos:/shares/photos"
    ];
  };

  systemd = {
    services = docker-services {
      name = "plex";
      image = image;
      setup-script = ''
        if ! zfs list r/varlib/plex >/dev/null 2>&1
        then
          zfs create r/varlib/plex
          chown plex:plex /var/lib/plex
          rsync -arPx --delete /nas/backup/varlib/plex/ /var/lib/plex/ || true
        fi
      '';
      backup-script = ''
        mkdir -p /nas/backup/varlib/plex
        rsync -arPx --delete /var/lib/plex/ /nas/backup/varlib/plex/
      '';
    };
  };
}
