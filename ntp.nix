{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  service = "ntp";
  image = "cturra/ntp";
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
in
if (machine.hostName != addresses.records."${service}".host) then {} else
{
  imports = [ ./docker.nix ];

  networking.firewall.allowedUDPPorts = [ 123 ];

  virtualisation.oci-containers.containers."${service}" = {
    image = image;
    autoStart = true;
    extraOptions = (addresses.dockerOptions service) ++ [
      "--read-only"
      "--tmpfs=/etc/chrony:rw,mode=1750"
      "--tmpfs=/run/chrony:rw,mode=1750"
      "--tmpfs=/var/lib/chrony:rw,mode=1750"
    ];
    ports = [
      "123/udp"
    ];
  };

  systemd = {
    services = docker-services {
      name = service;
      image = image;
    };
  };
}
