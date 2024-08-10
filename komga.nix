{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  image = "gotson/komga";
in
{
  imports = [ ./docker.nix ];

  networking.firewall = {
    allowedTCPPorts = [ 25600 ];
  };

  virtualisation.oci-containers.containers.komga = {
    image = image;
    autoStart = true;
    user = "${toString config.users.users.josh.uid}:${toString config.users.groups.plex.gid}";
    environment = {
      TZ = config.time.timeZone;
      SERVER_PORT = "25600";
    };
    ports = [
      "25600:25600"
    ];
    volumes = [
      "/var/lib/komga:/config"
      "/nas/media/Comics:/data"
    ];
  };

  systemd = {
    services = docker-services {
      name = "komga";
      image = image;
      setup-script = ''
        if ! zfs list r/varlib/komga >/dev/null 2>&1
        then
          zfs create r/varlib/komga
          chown josh:plex /var/lib/komga
          rsync -arPx --delete /nas/backup/varlib/komga/ /var/lib/komga/ || true
        fi
      '';
      backup-script = ''
        mkdir -p /nas/backup/varlib/komga
        rsync -arPx --delete /var/lib/komga/ /nas/backup/varlib/komga/
      '';
    };
  };
}
