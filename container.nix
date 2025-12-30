{ pkgs, lib, ... }:
let
  addresses = import ./addresses.nix { inherit lib; };
  machine = import ./machine.nix;
  executable = "docker";
  package = pkgs.docker;
  group = "docker";
  config = {
    virtualisation = {
      docker = {
        enable = true;
        enableOnBoot = true;
        autoPrune.enable = true;
        storageDriver = if machine.zfs then "zfs" else null;
        daemon.settings = {
          dns = [ "${addresses.records.pihole-1.ip}" "${addresses.records.pihole-2.ip}" "${addresses.records.pihole-3.ip}" ];
        };
      };
      oci-containers = {
        backend = executable;
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
          requiredBy = [ "${executable}.service" ];
          before = [ "${executable}.service" ];
        };
      } else { }) // {
        docker-configure = {
          path = [ pkgs.docker ];
          script = ''
            ${executable} network ls --format "{{.Name}}" | grep "^macvlan$" || ${executable} network create -d macvlan --ipv6 --subnet=${addresses.network.prefix}0.0/16 --gateway=${addresses.network.prefix}0.1 --subnet=${addresses.network.prefix6}/${toString addresses.network.prefix6Length} -o parent=${machine.lan-interface} -o macvlan_mode=bridge macvlan
          '';
          serviceConfig = {
            Type = "oneshot";
          };
          wantedBy = [ "${executable}.service" ];
          after = [ "${executable}.service" ];
        };
      };
    };
  };
in
{
  inherit executable package group config;
}
