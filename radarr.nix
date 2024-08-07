{ config, pkgs, ... }:

let
  image = "lscr.io/linuxserver/radarr";
in
{
  imports = [ ./docker.nix ];

  networking.firewall = {
    allowedTCPPorts = [ 7878 ];
  };

  virtualisation.oci-containers.containers.radarr = {
    image = "${image}";
    autoStart = true;
    environment = {
      PUID = "${toString config.users.users.josh.uid}";
      PGID = "${toString config.users.groups.plex.gid}";
      TZ = "${config.time.timeZone}";
    };
    ports = [
      "7878:7878"
    ];
    volumes = [
      "/var/lib/radarr:/config"
      "/nas/scratch/peer:/peer"
      "/nas/scratch/usenet:/usenet"
      "/nas/media:/media"
    ];
  };

  systemd = {
    services = {
      radarr-setup = {
        path = [ pkgs.zfs ];
        script = ''
          zfs list r/varlib/radarr >/dev/null 2>&1 || ( zfs create r/varlib/radarr && chown josh:plex /var/lib/radarr )
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        requiredBy = [ "docker-radarr.service" ];
        before = [ "docker-radarr.service" ];
      };
      radarr-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull ${image} | grep "Status: Downloaded"
          then
            systemctl restart docker-radarr
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
