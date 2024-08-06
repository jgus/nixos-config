{ config, pkgs, ... }:

let
  image = "lscr.io/linuxserver/lidarr";
in
{
  imports = [ ./docker.nix ];

  networking.firewall = {
    allowedTCPPorts = [ 8686 ];
  };

  virtualisation.oci-containers.containers.lidarr = {
    image = "${image}";
    autoStart = true;
    environment = {
      PUID = "${toString config.users.users.josh.uid}";
      PGID = "${toString config.users.groups.plex.gid}";
      TZ = "${config.time.timeZone}";
    };
    ports = [
      "8686:8686"
    ];
    volumes = [
      "/var/lib/lidarr:/config"
      "/d/scratch/peer:/peer"
      "/d/scratch/usenet:/usenet"
      "/d/media:/media"
    ];
  };

  systemd = {
    services = {
      lidarr-setup = {
        path = [ pkgs.zfs ];
        script = ''
          zfs list r/varlib/lidarr >/dev/null 2>&1 || ( zfs create r/varlib/lidarr && chown josh:plex /var/lib/lidarr )
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        requiredBy = [ "docker-lidarr.service" ];
        before = [ "docker-lidarr.service" ];
      };
      lidarr-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull ${image} | grep "Status: Downloaded"
          then
            systemctl restart docker-lidarr
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
