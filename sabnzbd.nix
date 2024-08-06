{ config, pkgs, ... }:

let
  image = "lscr.io/linuxserver/sabnzbd";
in
{
  imports = [ ./docker.nix ];

  networking.firewall = {
    allowedTCPPorts = [ 8080 ];
  };

  virtualisation.oci-containers.containers.sabnzbd = {
    image = "${image}";
    autoStart = true;
    environment = {
      PUID = "${toString config.users.users.josh.uid}";
      PGID = "${toString config.users.groups.plex.gid}";
      TZ = "${config.time.timeZone}";
    };
    ports = [
      "8080:8080"
    ];
    volumes = [
      "/var/lib/sabnzbd:/config"
      "/d/scratch/usenet:/config/Downloads"
    ];
  };

  systemd = {
    services = {
      sabnzbd-setup = {
        path = [ pkgs.zfs ];
        script = ''
          zfs list r/varlib/sabnzbd >/dev/null 2>&1 || ( zfs create r/varlib/sabnzbd && chown josh:plex /var/lib/sabnzbd )
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        requiredBy = [ "docker-sabnzbd.service" ];
        before = [ "docker-sabnzbd.service" ];
      };
      sabnzbd-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull ${image} | grep "Status: Downloaded"
          then
            systemctl restart docker-sabnzbd
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
