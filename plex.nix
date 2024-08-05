{ config, pkgs, ... }:

let
  image = "lscr.io/linuxserver/plex";
in
{
  imports = [ ./docker.nix ];

  system.activationScripts = {
    plexSetup.text = ''
      ${pkgs.zfs}/bin/zfs list r/varlib/plex >/dev/null 2>&1 || ( ${pkgs.zfs}/bin/zfs create r/varlib/plex && chown plex:plex /var/lib/plex )
    '';
  };

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
      "/d/media:/media"
      "/d/photos:/shares/photos"
    ];
  };

  systemd = {
    services = {
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
