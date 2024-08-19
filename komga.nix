{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  service = "komga";
  serviceMount = "var-lib-${builtins.replaceStrings ["-"] ["\\x2d"] service}.mount";
  user = "josh";
  group = "plex";
  image = "gotson/komga";
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
in
if (machine.hostName != addresses.records."${service}".host) then {} else
{
  imports = [ ./docker.nix ];

  virtualisation.oci-containers.containers."${service}" = {
    image = image;
    autoStart = true;
    extraOptions = (addresses.dockerOptions service);
    user = "${toString config.users.users."${user}".uid}:${toString config.users.groups."${group}".gid}";
    environment = {
      TZ = config.time.timeZone;
      SERVER_PORT = "25600";
    };
    ports = [
      "25600"
    ];
    volumes = [
      "/var/lib/${service}:/config"
      "/nas/media/Comics:/data"
    ];
  };

  fileSystems."/var/lib/${service}" = {
    device = "localhost:/varlib-${service}";
    fsType = "glusterfs";
  };

  systemd = {
    services = docker-services {
      name = service;
      image = image;
      requires = [ serviceMount "nas.mount" ];
    };
  };
}
