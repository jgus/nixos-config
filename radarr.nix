{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  image = "lscr.io/linuxserver/radarr";
in
{
  imports = [ ./docker.nix ];

  networking.firewall = {
    allowedTCPPorts = [ 7878 ];
  };

  virtualisation.oci-containers.containers.radarr = {
    image = image;
    autoStart = true;
    environment = {
      PUID = toString config.users.users.josh.uid;
      PGID = toString config.users.groups.plex.gid;
      TZ = config.time.timeZone;
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
    services = docker-services {
      name = "radarr";
      image = image;
      setup-script = ''
        if ! zfs list r/varlib/radarr >/dev/null 2>&1
        then
          zfs create r/varlib/radarr
          chown josh:plex /var/lib/radarr
          rsync -arPx --delete /nas/backup/varlib/radarr/ /var/lib/radarr/ || true
        fi
      '';
      backup-script = ''
        mkdir -p /nas/backup/varlib/radarr
        rsync -arPx --delete /var/lib/radarr/ /nas/backup/varlib/radarr/
      '';
    };
  };
}
