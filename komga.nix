{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  service = "komga";
  user = "josh";
  group = "plex";
  image = "gotson/komga";
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
in
if (machine.hostName != addresses.records."${service}".host) then {} else
{
  imports = [ ./docker.nix ];

  virtualisation.oci-containers.containers."${service}" = {
    image = image;
    autoStart = true;
    extraOptions = (addresses.dockerOptions service);
    user = "${toString config.users.users."${user}".uid}:${toString config.users.groups."${group}".gid}";
    environment = {
      TZ = config.time.timeZone;
      SERVER_PORT = "25600";
    };
    ports = [
      "25600"
    ];
    volumes = [
      "/var/lib/${service}:/config"
      "/nas/media/Comics:/data"
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
