{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  image = "lscr.io/linuxserver/mylar3";
in
{
  imports = [ ./docker.nix ];

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
      "/nas/media/Comics:/comics"
      "/nas/media/Comics.import:/import"
      "/nas/scratch/peer:/peer"
      "/nas/scratch/usenet:/usenet"
    ];
  };

  systemd = {
    services = docker-services {
      name = "mylar";
      image = image;
      setup-script = ''
        if ! zfs list r/varlib/mylar >/dev/null 2>&1
        then
          zfs create r/varlib/mylar
          chown josh:plex /var/lib/mylar
          rsync -arPx --delete /nas/backup/varlib/mylar/ /var/lib/mylar/ || true
        fi
      '';
      backup-script = ''
        mkdir -p /nas/backup/varlib/mylar
        rsync -arPx --delete /var/lib/mylar/ /nas/backup/varlib/mylar/
      '';
    };
  };
}
