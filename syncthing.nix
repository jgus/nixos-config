{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  service = "syncthing";
  image = "lscr.io/linuxserver/syncthing";
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
in
if (machine.hostName != addresses.records."${service}".host) then {} else
{
  imports = [ ./docker.nix ];

  networking.firewall = {
    allowedTCPPorts = [ 8384 22000 ];
    allowedUDPPorts = [ 21027 ];
  };

  virtualisation.oci-containers.containers."${service}" = {
    image = image;
    autoStart = true;
    ports = [
      "8384:8384"
      "22000:22000"
      "21027:21027/udp"
    ];
    environment = {
      PUID = toString config.users.users.josh.uid;
      PGID = toString config.users.groups.users.gid;
      TZ = config.time.timeZone;
      UMASK_SET = "002";
    };
    volumes = [
      "/var/lib/syncthing:/config"
      "/home/josh/sync:/shares/Sync"
      "/nas/photos:/shares/Photos"
      "/nas/software/Tools:/shares/Tools"
      "/nas/media/Comics:/shares/Comics"
      "/nas/media/Music:/shares/Music"
    ];
    extraOptions = (addresses.dockerOptions service);
  };

  fileSystems."/var/lib/${service}" = {
    device = "localhost:/varlib-${service}";
    fsType = "glusterfs";
  };

  systemd = {
    services = docker-services {
      name = service;
      image = image;
      requires = [ "var-lib-${service}.mount" "home.mount" "nas.mount" ];
    };
  };
}
