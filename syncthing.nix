{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  service = "syncthing";
  image = "lscr.io/linuxserver/syncthing";
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
in
if (machine.hostName != addresses.records."${service}".host) then {} else
{
  imports = [ ./docker.nix ];

  networking.firewall = {
    allowedTCPPorts = [ 8384 22000 ];
    allowedUDPPorts = [ 21027 ];
  };

  virtualisation.oci-containers.containers."${service}" = {
    image = image;
    autoStart = true;
    ports = [
      "8384:8384"
      "22000:22000"
      "21027:21027/udp"
    ];
    environment = {
      PUID = toString config.users.users.josh.uid;
      PGID = toString config.users.groups.users.gid;
      TZ = config.time.timeZone;
      UMASK_SET = "002";
    };
    volumes = [
      "/var/lib/syncthing:/config"
      "/home/josh/sync:/shares/Sync"
      "/nas/photos:/shares/Photos"
      "/nas/software/Tools:/shares/Tools"
      "/nas/media/Comics:/shares/Comics"
      "/nas/media/Music:/shares/Music"
    ];
    extraOptions = [
      "--network=macvlan"
      "--mac-address=${addresses.records.syncthing.mac}"
      "--ip=${addresses.records.syncthing.ip}"
    ];
  };

  systemd = {
    services = docker-services {
      name = "syncthing";
      image = image;
      setup-script = ''
        if ! zfs list r/varlib/${service} >/dev/null 2>&1
        then
          zfs create r/varlib/${service}
          chown josh:users /var/lib/${service}
          rsync -arPx --delete /nas/backup/varlib/${service}/ /var/lib/${service}/ || true
        fi
        zfs list r/varlib/${service}/index-v0.14.0.db >/dev/null 2>&1 || ( zfs create r/varlib/${service}/index-v0.14.0.db && chown josh:users /var/lib/${service}/index-v0.14.0.db )
      '';
      backup-script = ''
        mkdir -p /nas/backup/varlib/${service}
        rsync -arPx --delete /var/lib/${service}/ /nas/backup/varlib/${service}/
      '';
    };
  };
}
