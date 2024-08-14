{ config, pkgs, lib, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  service = "pihole";
  image = "pihole/pihole";
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
  pw = import ./.secrets/passwords.nix;
  dnsmasq-dns = with builtins; lib.concatStrings (map (ip: "host-record=" + (lib.concatStrings (map (s: "${s},") (getAttr ip addresses.hosts))) + ip + "\n") (attrNames addresses.hosts));
  dnsmasq-dhcp = with builtins; lib.concatStrings (map (r: "dhcp-host=" + r.mac + "," + r.ip + "," + r.name + ",infinite\n") addresses.dhcpReservations);
  dnsmasq-config = ''
    domain=home.gustafson.me
    dhcp-option=option:ntp-server,${addresses.nameToIp.ntp}
  '';
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
    ports = [
      "53"
      "67/udp"
      "80/tcp"
      "443/tcp"
    ];
    environment = {
      TZ = config.time.timeZone;
      WEBPASSWORD = pw.pihole;
      FTLCONF_LOCAL_IPV4 = addresses.services."${service}".ip;
      PIHOLE_DNS_ = "1.1.1.1;1.0.0.1;8.8.8.8;8.8.4.4";
      DNSSEC = "true";
      DHCP_ACTIVE = "true";
      DHCP_START = "172.22.200.1";
      DHCP_END = "172.22.254.254";
      DHCP_ROUTER = addresses.network.defaultGateway;
      VIRTUAL_HOST = "${service}.${addresses.network.domain}";
    };
    volumes = [
      "/var/lib/${service}/pihole:/etc/pihole"
      "/var/lib/${service}/dnsmasq.d:/etc/dnsmasq.d"
      "${pkgs.writeText "50-nixos-dns.conf" dnsmasq-dns}:/etc/dnsmasq.d/50-nixos-dns.conf"
      "${pkgs.writeText "50-nixos-dhcp.conf" dnsmasq-dhcp}:/etc/dnsmasq.d/50-nixos-dhcp.conf"
      "${pkgs.writeText "50-nixos-config.conf" dnsmasq-config}:/etc/dnsmasq.d/50-nixos-config.conf"
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
