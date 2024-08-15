{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  service = "mylar";
  user = "josh";
  group = "plex";
  image = "lscr.io/linuxserver/mylar3";
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
in
if (machine.hostName != addresses.records."${service}".host) then {} else
{
  imports = [ ./docker.nix ];

  virtualisation.oci-containers.containers."${service}" = {
    image = image;
    autoStart = true;
    extraOptions = (addresses.dockerOptions service) ++ [
      "--tmpfs=/config/mylar/cache"
    ];
    environment = {
      PUID = toString config.users.users."${user}".uid;
      PGID = toString config.users.groups."${group}".gid;
      TZ = config.time.timeZone;
    };
    ports = [
      "8090"
    ];
    volumes = [
      "/var/lib/${service}:/config"
      "/nas/media/Comics:/comics"
      "/nas/media/Comics.import:/import"
      "/nas/scratch/peer:/peer"
      "/nas/scratch/usenet:/usenet"
    ];
  };

  systemd = {
    services = docker-services {
      name = service;
      image = image;
      setup-script = ''
        if ! zfs list r/varlib/${service} >/dev/null 2>&1
        then
          zfs create r/varlib/${service}
          chown ${user}:${group} /var/lib/${service}
          rsync -arPx --delete /nas/backup/varlib/${service}/ /var/lib/${service}/ || true
        fi
      '';
      backup-script = ''
        mkdir -p /nas/backup/varlib/${service}
        rsync -arPx --delete /var/lib/${service}/ /nas/backup/varlib/${service}/
      '';
    };
  };
}
