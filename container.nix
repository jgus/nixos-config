{ lib, pkgs, machine, addresses, ... }:
let
  executable = "podman";
  package = pkgs.podman;
  group = "podman";
  config = {
    virtualisation = {
      podman = {
        enable = true;
        autoPrune.enable = true;
      };
      oci-containers = {
        backend = executable;
      };
    };

    systemd = {
      services = lib.optionalAttrs machine.zfs
        {
          podman-setup = {
            path = [ pkgs.zfs ];
            script = ''
              zfs list r/varlib/containers >/dev/null 2>&1 || zfs create r/varlib/containers
            '';
            serviceConfig = {
              Type = "oneshot";
            };
            requiredBy = [ "${executable}.service" ];
            before = [ "${executable}.service" ];
          };
        } // {
        podman-configure = {
          path = [ package ];
          script = ''
            ${executable} network ls --format "{{.Name}}" | grep "^macvlan$" || ${executable} network create -d macvlan --ipv6 --subnet=${addresses.network.prefix}0.0/16 --gateway=${addresses.network.prefix}0.1 --subnet=${addresses.network.prefix6}/${toString addresses.network.prefix6Length} -o parent=${machine.lan-interface} macvlan
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
