{ config, pkgs, lib, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  service = "pihole";
  image = "pihole/pihole";
  serviceMount = "var-lib-${builtins.replaceStrings ["-"] ["\\x2d"] service}.mount";
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
  pw = import ./.secrets/passwords.nix;
  dnsmasq-dns = with builtins; lib.concatStrings (map (ip: "host-record=" + (lib.concatStrings (map (s: "${s},") (getAttr ip addresses.hosts))) + ip + "\n") (attrNames addresses.hosts));
  dnsmasq-dhcp = with builtins; lib.concatStrings (map (r: "dhcp-host=" + r.mac + "," + r.ip + "," + r.name + ",infinite\n") addresses.dhcpReservations);
  dnsmasq-config = ''
    dhcp-option=option:ntp-server,${addresses.nameToIp.ntp}
  '';
in
if (machine.hostName != addresses.records."${service}".host) then {} else
{
  imports = [ ./docker.nix ];

  virtualisation.oci-containers.containers."${service}" = {
    image = image;
    autoStart = true;
    extraOptions = (addresses.dockerOptions service) ++ [
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
      FTLCONF_LOCAL_IPV4 = addresses.records."${service}".ip;
      PIHOLE_DNS_ = "1.1.1.1;1.0.0.1;8.8.8.8;8.8.4.4";
      DNSSEC = "true";
      DHCP_ACTIVE = "true";
      DHCP_START = "172.22.200.1";
      DHCP_END = "172.22.254.254";
      DHCP_ROUTER = addresses.network.defaultGateway;
      PIHOLE_DOMAIN = addresses.network.domain;
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
