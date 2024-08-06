{ config, pkgs, ... }:

let
  image = "ghcr.io/esphome/esphome";
in
{
  imports = [ ./docker.nix ];

  networking.firewall.allowedTCPPorts = [ 6052 ];

  virtualisation.oci-containers.containers.esphome = {
    image = "${image}";
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
    services = {
      esphome-setup = {
        path = [ pkgs.zfs ];
        script = ''
          zfs list r/varlib/esphome >/dev/null 2>&1 || ( zfs create r/varlib/esphome && chown josh:users /var/lib/esphome )
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        requiredBy = [ "docker-esphome.service" ];
        before = [ "docker-esphome.service" ];
      };
      esphome-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull ${image} | grep "Status: Downloaded"
          then
            systemctl restart docker-esphome
          fi
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        startAt = "hourly";
      };
    };
  };
}
