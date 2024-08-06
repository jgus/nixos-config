{ config, pkgs, ... }:

let
  image = "lscr.io/linuxserver/prowlarr";
in
{
  imports = [ ./docker.nix ];

  networking.firewall = {
    allowedTCPPorts = [ 9696 ];
  };

  virtualisation.oci-containers.containers.prowlarr = {
    image = "${image}";
    autoStart = true;
    environment = {
      PUID = "${toString config.users.users.josh.uid}";
      PGID = "${toString config.users.groups.plex.gid}";
      TZ = "${config.time.timeZone}";
    };
    ports = [
      "9696:9696"
    ];
    volumes = [
      "/var/lib/prowlarr:/config"
    ];
  };

  systemd = {
    services = {
      prowlarr-setup = {
        path = [ pkgs.zfs ];
        script = ''
          zfs list r/varlib/prowlarr >/dev/null 2>&1 || ( zfs create r/varlib/prowlarr && chown josh:plex /var/lib/prowlarr )
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        requiredBy = [ "docker-prowlarr.service" ];
        before = [ "docker-prowlarr.service" ];
      };
      prowlarr-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull ${image} | grep "Status: Downloaded"
          then
            systemctl restart docker-prowlarr
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
