{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  service = "syncthing";
  serviceMount = "var-lib-${builtins.replaceStrings ["-"] ["\\x2d"] service}.mount";
  image = "lscr.io/linuxserver/syncthing";
  user = "josh";
  group = "users";
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
in
if (machine.hostName != addresses.records."${service}".host) then {} else
{
  imports = [
    ./docker.nix
    (docker-services {
      name = service;
      image = image;
      requires = [ serviceMount "home.mount" "nas.mount" ];
    })
  ];

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
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
      UMASK_SET = "002";
    };
    volumes = [
      "/var/lib/syncthing:/config"
      "/home/${user}/sync:/shares/Sync"
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
}
