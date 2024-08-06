{ config, pkgs, ... }:

let
  image = "lscr.io/linuxserver/sonarr";
in
{
  imports = [ ./docker.nix ];

  networking.firewall = {
    allowedTCPPorts = [ 8989 ];
  };

  virtualisation.oci-containers.containers.sonarr = {
    image = "${image}";
    autoStart = true;
    environment = {
      PUID = "${toString config.users.users.josh.uid}";
      PGID = "${toString config.users.groups.plex.gid}";
      TZ = "${config.time.timeZone}";
    };
    ports = [
      "8989:8989"
    ];
    volumes = [
      "/var/lib/sonarr:/config"
      "/d/scratch/peer:/peer"
      "/d/scratch/usenet:/usenet"
      "/d/media:/media"
    ];
  };

  systemd = {
    services = {
      sonarr-setup = {
        path = [ pkgs.zfs ];
        script = ''
          zfs list r/varlib/sonarr >/dev/null 2>&1 || ( zfs create r/varlib/sonarr && chown josh:plex /var/lib/sonarr )
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        requiredBy = [ "docker-sonarr.service" ];
        before = [ "docker-sonarr.service" ];
      };
      sonarr-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull ${image} | grep "Status: Downloaded"
          then
            systemctl restart docker-sonarr
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
