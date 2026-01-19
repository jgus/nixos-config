with builtins;
{ addresses, config, lib, machine, pkgs, ... }:
{
  options.ext.container.enable = lib.mkEnableOption "Enable Contianer Support";

  config = lib.mkIf config.ext.container.enable {
    virtualisation = {
      podman = {
        enable = true;
        autoPrune.enable = true;
      };
      oci-containers = {
        backend = "podman";
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
            requiredBy = [ "podman.service" ];
            before = [ "podman.service" ];
          };
        } // {
        podman-configure = lib.mkOverride 1500 {
          path = [ pkgs.podman ];
          script =
            let
              suffixes = lib.concatStringsSep " " (map (vlan: ".${toString vlan.vlanId}") (attrValues addresses.vlans));
            in
            ''
              for SUFFIX in "" ${suffixes}
              do
                podman network ls --format "{{.Name}}" | grep "^hostlan''${SUFFIX}$" || podman network create -d macvlan --ipv6 --subnet=${addresses.network.net4} --gateway=${addresses.network.defaultGateway} --subnet=${addresses.network.net6} -o parent=br0''${SUFFIX} hostlan''${SUFFIX}
              done
            '';
          serviceConfig = {
            Type = "oneshot";
          };
          wantedBy = [ "multi-user.target" ];
          requires = [ "podman.service" ];
          after = [ "podman.service" ];
        };
      };
    };
  };
}
