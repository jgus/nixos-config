{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  service = "esphome";
  image = "ghcr.io/esphome/esphome";
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
in
if (machine.hostName != addresses.records."${service}".host) then {} else
{
  imports = [ ./docker.nix ];

  networking.firewall.allowedTCPPorts = [ 6052 ];

  virtualisation.oci-containers.containers."${service}" = {
    image = image;
    autoStart = true;
    user = "${toString config.users.users.josh.uid}:${toString config.users.groups.users.gid}";
    extraOptions = [
      "--network=macvlan"
      "--mac-address=${addresses.records."${service}".mac}"
      "--ip=${addresses.records."${service}".ip}"
      "--tmpfs=/cache:exec,uid=${toString config.users.users.josh.uid},gid=${toString config.users.groups.users.gid}"
      "--tmpfs=/.cache/pip:exec,uid=${toString config.users.users.josh.uid},gid=${toString config.users.groups.users.gid}"
      "--tmpfs=/config/.esphome/build:exec,uid=${toString config.users.users.josh.uid},gid=${toString config.users.groups.users.gid}"
      "--tmpfs=/config/.esphome/external_components:exec,uid=${toString config.users.users.josh.uid},gid=${toString config.users.groups.users.gid}"
    ];
    environment = {
      PLATFORMIO_CORE_DIR = "/cache/.plattformio";
      PLATFORMIO_GLOBALLIB_DIR = "/cache/.plattformioLibs";
    };
    volumes = [
      "/var/lib/${service}:/config"
    ];
  };

  systemd = {
    services = docker-services {
      name = "${service}";
      image = image;
      setup-script = ''
        if ! zfs list r/varlib/${service} >/dev/null 2>&1
        then
          zfs create r/varlib/${service}
          chown josh:users /var/lib/${service}
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
