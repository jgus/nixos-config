{ config, pkgs, area, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  service = "zwave-${area}";
  serviceMount = "var-lib-${builtins.replaceStrings ["-"] ["\\x2d"] service}.mount";
  image = "zwavejs/zwave-js-ui";
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
  device = "/dev/serial/by-id/usb-Zooz_800_Z-Wave_Stick_533D004242-if00";
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
    extraOptions = (addresses.dockerOptions service) ++ [
      "--device=${device}:/dev/zwave"
    ];
    ports = [
      "8091"
      "3000"
    ];
    environment = {
      TZ = config.time.timeZone;
    };
    volumes = [
      "/var/lib/${service}:/usr/src/app/store"
    ];
  };

  fileSystems."/var/lib/${service}" = {
    device = "localhost:/varlib-${service}";
    fsType = "glusterfs";
  };
}
