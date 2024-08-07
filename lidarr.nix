{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
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
      "/nas/scratch/peer:/peer"
      "/nas/scratch/usenet:/usenet"
      "/nas/media:/media"
    ];
  };

  systemd = {
    services = docker-services {
      name = "lidarr";
      image = image;
      setup-script = ''
        if ! zfs list r/varlib/lidarr >/dev/null 2>&1
        then
          zfs create r/varlib/lidarr
          chown josh:plex /var/lib/lidarr
          rsync -arPx --delete /nas/backup/varlib/lidarr/ /var/lib/lidarr/ || true
        fi
      '';
      backup-script = ''
        mkdir -p /nas/backup/varlib/lidarr
        rsync -arPx --delete /var/lib/lidarr/ /nas/backup/varlib/lidarr/
      '';
    };
  };
}
