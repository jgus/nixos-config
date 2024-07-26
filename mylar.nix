{ config, pkgs, ... }:

let
  image = "lscr.io/linuxserver/mylar3";
in
{
  imports = [ ./docker.nix ];

  system.activationScripts = {
    docker-setup.text = ''
      ${pkgs.zfs}/bin/zfs list r/varlib/mylar >/dev/null 2>&1 || ( ${pkgs.zfs}/bin/zfs create r/varlib/mylar && chown josh:plex /var/lib/mylar )
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [ 8090 ];
  };

  virtualisation.oci-containers.containers.mylar = {
    image = "${image}";
    autoStart = true;
    extraOptions = [
      "--tmpfs=/config/mylar/cache"
    ];
    environment = {
      PUID = "${toString config.users.users.josh.uid}";
      PGID = "${toString config.users.groups.plex.gid}";
      TZ = "${config.time.timeZone}";
    };
    ports = [
      "8090:8090"
    ];
    volumes = [
      "/var/lib/mylar:/config"
      "/d/media/Comics:/comics"
      "/d/media/Comics.import:/import"
      "/d/scratch/peer:/peer"
      "/d/scratch/usenet:/usenet"
    ];
  };

  systemd = {
    services = {
      mylar-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull ${image} | grep "Status: Downloaded"
          then
            systemctl restart docker-mylar
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