{ config, pkgs, lib, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  service = "pihole";
  image = "pihole/pihole";
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
  pw = import ./.secrets/passwords.nix;
  dnsmasq-entries = with builtins; lib.concatStrings (map (ip: "host-record=" + (lib.concatStrings (map (s: "${s},") (getAttr ip addresses.hosts))) + ip + "\n") (attrNames addresses.hosts));
in
if (machine.hostName != addresses.services."${service}".host) then {} else
{
  imports = [ ./docker.nix ];

  virtualisation.oci-containers.containers."${service}" = {
    image = image;
    autoStart = true;
    extraOptions = [
      "--network=macvlan"
      "--mac-address=${addresses.services."${service}".mac}"
      "--ip=${addresses.services."${service}".ip}"
      "--cap-add=NET_ADMIN"
    ];
    environment = {
      TZ = config.time.timeZone;
      WEBPASSWORD = pw.pihole;
      FTLCONF_LOCAL_IPV4 = addresses.services."${service}".ip;
      VIRTUAL_HOST = "${service}.${addresses.network.domain}";
    };
    volumes = [
      "/var/lib/${service}/pihole:/etc/pihole"
      "/var/lib/${service}/dnsmasq.d:/etc/dnsmasq.d"
      "${pkgs.writeText "50-nixos.conf" dnsmasq-entries}:/etc/dnsmasq.d/50-nixos.conf"
    ];
  };

  systemd = {
    services = docker-services {
      name = service;
      image = image;
      setup-script = ''
        if ! zfs list r/varlib/${service} >/dev/null 2>&1
        then
          zfs create r/varlib/${service}
          mkdir -p /var/lib/${service}/pihole
          mkdir -p /var/lib/${service}/dnsmasq.d
          rsync -arPx --delete /nas/backup/varlib/${service}/ /var/lib/${service}/ || true
        fi
      '';
      backup-script = ''
        mkdir -p /nas/backup/varlib/${service}
        rsync -arPx --delete /var/lib/${service}/ /nas/backup/varlib/${service}/
      '';
    };
  };
}
