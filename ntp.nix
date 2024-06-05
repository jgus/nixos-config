{ config, pkgs, ... }:

let
  image = "cturra/ntp";
in
{
  imports = [ ./docker.nix ];

  networking.firewall.allowedUDPPorts = [ 123 ];

  virtualisation.oci-containers.containers.ntp = {
    image = "${image}";
    autoStart = true;
    extraOptions = [
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
    services = {
      ntp-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull ${image} | grep "Status: Downloaded"
          then
            systemctl restart docker-ntp
          fi
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        startAt = "hourly";
      };
    };
  };
}
