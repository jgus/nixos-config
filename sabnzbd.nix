{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  image = "lscr.io/linuxserver/sabnzbd";
in
{
  imports = [ ./docker.nix ];

  networking.firewall = {
    allowedTCPPorts = [ 8080 ];
  };

  virtualisation.oci-containers.containers.sabnzbd = {
    image = image;
    autoStart = true;
    environment = {
      PUID = toString config.users.users.josh.uid;
      PGID = toString config.users.groups.plex.gid;
      TZ = config.time.timeZone;
    };
    ports = [
      "8080:8080"
    ];
    volumes = [
      "/var/lib/sabnzbd:/config"
      "/nas/scratch/usenet:/config/Downloads"
    ];
  };

  systemd = {
    services = docker-services {
      name = "sabnzbd";
      image = image;
      setup-script = ''
        if ! zfs list r/varlib/sabnzbd >/dev/null 2>&1
        then
          zfs create r/varlib/sabnzbd
          chown josh:plex /var/lib/sabnzbd
          rsync -arPx --delete /nas/backup/varlib/sabnzbd/ /var/lib/sabnzbd/ || true
        fi
      '';
      backup-script = ''
        mkdir -p /nas/backup/varlib/sabnzbd
        rsync -arPx --delete /var/lib/sabnzbd/ /nas/backup/varlib/sabnzbd/
      '';
    };
  };
}
