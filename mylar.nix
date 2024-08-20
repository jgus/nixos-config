{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  service = "mylar";
  serviceMount = "var-lib-${builtins.replaceStrings ["-"] ["\\x2d"] service}.mount";
  user = "josh";
  group = "plex";
  image = "lscr.io/linuxserver/mylar3";
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
      requires = [ serviceMount "nas.mount" ];
    })
  ];

  virtualisation.oci-containers.containers."${service}" = {
    image = image;
    autoStart = true;
    extraOptions = (addresses.dockerOptions service) ++ [
      "--tmpfs=/config/mylar/cache"
    ];
    environment = {
      PUID = toString config.users.users."${user}".uid;
      PGID = toString config.users.groups."${group}".gid;
      TZ = config.time.timeZone;
    };
    ports = [
      "8090"
    ];
    volumes = [
      "/var/lib/${service}:/config"
      "/nas/media/Comics:/comics"
      "/nas/media/Comics.import:/import"
      "/nas/scratch/peer:/peer"
      "/nas/scratch/usenet:/usenet"
    ];
  };

  fileSystems."/var/lib/${service}" = {
    device = "localhost:/varlib-${service}";
    fsType = "glusterfs";
  };
}
