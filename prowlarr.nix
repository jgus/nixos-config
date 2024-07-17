{ config, pkgs, ... }:

let
  image = "lscr.io/linuxserver/prowlarr";
in
{
  imports = [ ./docker.nix ];

  system.activationScripts = {
    docker-setup.text = ''
      ${pkgs.zfs}/bin/zfs list r/varlib/prowlarr >/dev/null 2>&1 || ( ${pkgs.zfs}/bin/zfs create r/varlib/prowlarr && chown josh:plex /var/lib/prowlarr )
    '';
  };

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
