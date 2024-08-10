{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  image = "ghcr.io/esphome/esphome";
in
{
  imports = [ ./docker.nix ];

  networking.firewall.allowedTCPPorts = [ 6052 ];

  virtualisation.oci-containers.containers.esphome = {
    image = image;
    autoStart = true;
    user = "${toString config.users.users.josh.uid}:${toString config.users.groups.users.gid}";
    extraOptions = [
      "--net=host"
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
      "/var/lib/esphome:/config"
    ];
  };

  systemd = {
    services = docker-services {
      name = "esphome";
      image = image;
      setup-script = ''
        if ! zfs list r/varlib/esphome >/dev/null 2>&1
        then
          zfs create r/varlib/esphome
          chown josh:users /var/lib/esphome
          rsync -arPx --delete /nas/backup/varlib/esphome/ /var/lib/esphome/ || true
        fi
      '';
      backup-script = ''
        mkdir -p /nas/backup/varlib/esphome
        rsync -arPx --delete /var/lib/esphome/ /nas/backup/varlib/esphome/
      '';
    };
  };
}
