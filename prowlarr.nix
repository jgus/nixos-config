{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  service = "prowlarr";
  serviceMount = "var-lib-${builtins.replaceStrings ["-"] ["\\x2d"] service}.mount";
  user = "josh";
  group = "plex";
  image = "lscr.io/linuxserver/prowlarr";
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
      requires = [ serviceMount ];
    })
  ];

  virtualisation.oci-containers.containers."${service}" = {
    image = image;
    autoStart = true;
    extraOptions = (addresses.dockerOptions service);
    environment = {
      PUID = toString config.users.users."${user}".uid;
      PGID = toString config.users.groups."${group}".gid;
      TZ = config.time.timeZone;
    };
    ports = [
      "9696"
    ];
    volumes = [
      "/var/lib/${service}:/config"
    ];
  };

  fileSystems."/var/lib/${service}" = {
    device = "localhost:/varlib-${service}";
    fsType = "glusterfs";
  };
}
