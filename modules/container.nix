with builtins;
{ addresses, config, lib, machine, pkgs, ... }:
{
  options.homelab.container = {
    enable = lib.mkEnableOption "Enable Contianer Support";
    engine = lib.mkOption {
      type = lib.types.enum [ "docker" "podman" ];
      default = "docker";
      description = "Container engine to use (docker or podman)";
    };

    executable = lib.mkOption {
      type = lib.types.str;
      default = config.homelab.container.engine;
      readOnly = true;
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.${config.homelab.container.engine};
      readOnly = true;
    };
    group = lib.mkOption {
      type = lib.types.str;
      default = config.homelab.container.engine;
      readOnly = true;
    };
  };

  config = lib.mkIf config.homelab.container.enable {
    virtualisation = {
      docker = lib.optionalAttrs (config.homelab.container.engine == "docker") (throw "Not Implemented");
      podman = lib.mkIf (config.homelab.container.engine == "podman") {
        enable = true;
        autoPrune.enable = true;
      };
      oci-containers = {
        backend = config.homelab.container.engine;
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
          script = lib.concatStringsSep "\n" (map
            (vlan:
              let
                suffix = if vlan ? vlanId then ".${toString vlan.vlanId}" else "";
              in
              ''
                podman network ls --format "{{.Name}}" | grep "^hostlan${suffix}$" || podman network create -d macvlan --ipv6 --subnet=${vlan.net4} --gateway=${vlan.defaultGateway} ${lib.optionalString (vlan ? net6) "--subnet=${vlan.net6}"} -o parent=br0${suffix} hostlan${suffix}
              ''
            )
            ([ addresses.network ] ++ (attrValues addresses.vlans)));
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
