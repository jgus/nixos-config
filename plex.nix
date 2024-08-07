{ config, pkgs, ... }:

let
  image = "lscr.io/linuxserver/plex";
in
{
  imports = [ ./docker.nix ];

  networking.firewall.allowedTCPPorts = [ 32400 ];
  networking.firewall.allowedUDPPorts = [ 32410 32412 32413 32414 ];

  virtualisation.oci-containers.containers.plex = {
    image = "${image}";
    autoStart = true;
    extraOptions = [
      "--net=host"
      "--gpus=all"
      "--device=/dev/dri:/dev/dri"
      "--tmpfs=/tmp"
    ];
    ports = [
      "8384:8384"
      "22000:22000"
      "21027:21027/udp"
    ];
    environment = {
      PUID = "${toString config.users.users.plex.uid}";
      PGID = "${toString config.users.groups.plex.gid}";
      TZ = "${config.time.timeZone}";
      VERSION = "latest";
    };
    volumes = [
      "/var/lib/plex:/config"
      "/nas/media:/media"
      "/nas/photos:/shares/photos"
    ];
  };

  systemd = {
    services = {
      plex-setup = {
        path = [ pkgs.zfs ];
        script = ''
          zfs list r/varlib/plex >/dev/null 2>&1 || ( zfs create r/varlib/plex && chown plex:plex /var/lib/plex )
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        requiredBy = [ "docker-plex.service" ];
        before = [ "docker-plex.service" ];
      };
      plex-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull ${image} | grep "Status: Downloaded"
          then
            systemctl restart docker-plex
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
