{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
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
      "/nas/scratch/peer:/peer"
      "/nas/scratch/usenet:/usenet"
      "/nas/media:/media"
    ];
  };

  systemd = {
    services = docker-services {
      name = "sonarr";
      image = image;
      setup-script = ''
        if ! zfs list r/varlib/sonarr >/dev/null 2>&1
        then
          zfs create r/varlib/sonarr
          chown josh:plex /var/lib/sonarr
          rsync -arPx --delete /nas/backup/varlib/sonarr/ /var/lib/sonarr/ || true
        fi
      '';
      backup-script = ''
        mkdir -p /nas/backup/varlib/sonarr
        rsync -arPx --delete /var/lib/sonarr/ /nas/backup/varlib/sonarr/
      '';
    };
  };
}
