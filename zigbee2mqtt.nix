{ config, pkgs, lib, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  pw = import ./.secrets/passwords.nix;
  service = "zigbee2mqtt";
  serviceMount = "var-lib-${builtins.replaceStrings ["-"] ["\\x2d"] service}.mount";
  image = "koenkk/zigbee2mqtt";
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
      TZ = config.time.timeZone;
    };
    ports = [
      "8081"
    ];
    volumes = [
      "/var/lib/${service}:/app/data"
    ];
  };

  fileSystems."/var/lib/${service}" = {
    device = "localhost:/varlib-${service}";
    fsType = "glusterfs";
  };
}
