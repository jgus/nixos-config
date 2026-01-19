with builtins;
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
        podman-configure = lib.mkOverride 1500 {
          path = [ package ];
          script =
            let
              suffixes = lib.concatStringsSep " " (map (vlan: ".${toString vlan.vlanId}") (attrValues addresses.vlans));
            in
            ''
              for SUFFIX in "" ${suffixes}
              do
                ${executable} network ls --format "{{.Name}}" | grep "^hostlan''${SUFFIX}$" || ${executable} network create -d macvlan --ipv6 --subnet=${addresses.network.net4} --gateway=${addresses.network.defaultGateway} --subnet=${addresses.network.net6} -o parent=br0''${SUFFIX} hostlan''${SUFFIX}
              done
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
