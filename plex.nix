{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  service = "plex";
  serviceMount = "var-lib-${builtins.replaceStrings ["-"] ["\\x2d"] service}.mount";
  user = "plex";
  group = "plex";
  image = "lscr.io/linuxserver/plex";
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
      "--gpus=all"
      "--device=/dev/dri:/dev/dri"
      "--tmpfs=/tmp"
    ];
    environment = {
      PUID = toString config.users.users."${user}".uid;
      PGID = toString config.users.groups."${group}".gid;
      TZ = config.time.timeZone;
      VERSION = "latest";
    };
    volumes = [
      "/var/lib/${service}:/config"
      "/nas/media:/media"
      "/nas/photos:/shares/photos"
    ];
  };

  fileSystems."/var/lib/${service}" = {
    device = "localhost:/varlib-${service}";
    fsType = "glusterfs";
  };
}
