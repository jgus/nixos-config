{ config, pkgs, lib, ... }:

let
  machine = import ./machine.nix;
in
{
  virtualisation = {
    docker = {
      enable = true;
      enableOnBoot = true;
      autoPrune.enable = true;
      storageDriver = if machine.zfs then "zfs" else null;
      daemon.settings = {
        dns = [ "172.22.0.1" ];
      };
    };
    oci-containers = {
      backend = "docker";
      containers = {};
    };
  };

  systemd = {
    services = (if machine.zfs then {
      docker-setup = {
        path = [ pkgs.zfs ];
        script = ''
          zfs list r/varlib/docker >/dev/null 2>&1 || zfs create r/varlib/docker
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        requiredBy = [ "docker.service" ];
        before = [ "docker.service" ];
      };
    } else {}) // {
      docker-configure = {
        path = [ pkgs.docker ];
        script = ''
          docker network ls --format "{{.Name}}" | grep "^macvlan$" || docker network create -d macvlan --subnet=172.22.0.0/16 --gateway=172.22.0.1 -o parent=${machine.lan-interface} -o macvlan_mode=bridge macvlan
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        wantedBy = [ "docker.service" ];
        after = [ "docker.service" ];
      };
    };
  };
}
