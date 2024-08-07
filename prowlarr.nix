{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  image = "lscr.io/linuxserver/prowlarr";
in
{
  imports = [ ./docker.nix ];

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
    services = docker-services {
      name = "prowlarr";
      image = image;
      setup-script = ''
        if ! zfs list r/varlib/prowlarr >/dev/null 2>&1
        then
          zfs create r/varlib/prowlarr
          chown josh:plex /var/lib/prowlarr
          rsync -arPx --delete /nas/backup/varlib/prowlarr/ /var/lib/prowlarr/ || true
        fi
      '';
      backup-script = ''
        mkdir -p /nas/backup/varlib/prowlarr
        rsync -arPx --delete /var/lib/prowlarr/ /nas/backup/varlib/prowlarr/
      '';
    };
  };
}
