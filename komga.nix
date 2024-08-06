{ config, pkgs, ... }:

let
  image = "gotson/komga";
in
{
  imports = [ ./docker.nix ];

  networking.firewall = {
    allowedTCPPorts = [ 25600 ];
  };

  virtualisation.oci-containers.containers.komga = {
    image = "${image}";
    autoStart = true;
    user = "${toString config.users.users.josh.uid}:${toString config.users.groups.plex.gid}";
    environment = {
      TZ = "${config.time.timeZone}";
      SERVER_PORT = "25600";
    };
    ports = [
      "25600:25600"
    ];
    volumes = [
      "/var/lib/komga:/config"
      "/d/media/Comics:/data"
    ];
  };

  systemd = {
    services = {
      komga-setup = {
        path = [ pkgs.zfs ];
        script = ''
          zfs list r/varlib/komga >/dev/null 2>&1 || ( zfs create r/varlib/komga && chown josh:plex /var/lib/komga )
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        requiredBy = [ "docker-komga.service" ];
        before = [ "docker-komga.service" ];
      };
      komga-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull ${image} | grep "Status: Downloaded"
          then
            systemctl restart docker-komga
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
