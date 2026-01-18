{ addresses, lib, machine, pkgs, ... }:
rec {
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
            ${executable} network ls --format "{{.Name}}" | grep "^hostlan$" || ${executable} network create -d macvlan --ipv6 --subnet=${addresses.network.net4} --gateway=${addresses.network.defaultGateway} --subnet=${addresses.network.net6} -o parent=lan0 hostlan
          '';
          serviceConfig = {
            Type = "oneshot";
          };
          wantedBy = [ "multi-user.target" ];
          requires = [ "${executable}.service" ];
          after = [ "${executable}.service" ];
        };
      };
    };
  };
}
