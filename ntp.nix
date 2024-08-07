{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  image = "cturra/ntp";
  addresses = import ./addresses.nix;
in
{
  imports = [ ./docker.nix ];

  networking.firewall.allowedUDPPorts = [ 123 ];

  virtualisation.oci-containers.containers.ntp = {
    image = "${image}";
    autoStart = true;
    extraOptions = [
      "--network=macvlan"
      "--mac-address=${addresses.services.ntp.mac}"
      "--ip=${addresses.services.ntp.ip}"
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
      name = "ntp";
      image = image;
    };
  };
}
