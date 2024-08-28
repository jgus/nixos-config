{ config, pkgs, lib, ... }:
with builtins;
let
  name = "pihole";
  addresses = import ./../addresses.nix;
  pw = import ./../.secrets/passwords.nix;
  dnsmasq-dns = lib.concatStrings (map (ip: "host-record=" + (lib.concatStrings (map (s: "${s},") (getAttr ip addresses.hosts))) + ip + "\n") (attrNames addresses.hosts));
  dnsmasq-dhcp = lib.concatStrings (map (r: "dhcp-host=" + r.mac + "," + r.ip + "," + r.name + ",infinite\n") addresses.dhcpReservations);
  dnsmasq-config = ''
    dhcp-option=option:ntp-server,${addresses.nameToIp.ntp}
  '';
in
{
  docker = {
    image = "pihole/pihole";
    environment = {
      TZ = config.time.timeZone;
      WEBPASSWORD = pw.pihole;
      FTLCONF_LOCAL_IPV4 = addresses.records.${name}.ip;
      PIHOLE_DNS_ = "1.1.1.1;1.0.0.1;8.8.8.8;8.8.4.4";
      DNSSEC = "true";
      DHCP_ACTIVE = "true";
      DHCP_START = "172.22.200.1";
      DHCP_END = "172.22.254.254";
      DHCP_ROUTER = addresses.network.defaultGateway;
      PIHOLE_DOMAIN = addresses.network.domain;
      VIRTUAL_HOST = "${name}.${addresses.network.domain}";
    };
    ports = [
      "53"
      "67/udp"
      "80/tcp"
      "443/tcp"
    ];
    configVolume = "/config";
    volumes = storagePath: [
      "${storagePath name}/pihole:/etc/pihole"
      "${storagePath name}/dnsmasq.d:/etc/dnsmasq.d"
      "${pkgs.writeText "50-nixos-dns.conf" dnsmasq-dns}:/etc/dnsmasq.d/50-nixos-dns.conf"
      "${pkgs.writeText "50-nixos-dhcp.conf" dnsmasq-dhcp}:/etc/dnsmasq.d/50-nixos-dhcp.conf"
      "${pkgs.writeText "50-nixos-config.conf" dnsmasq-config}:/etc/dnsmasq.d/50-nixos-config.conf"
    ];
    extraOptions = [
      "--cap-add=NET_ADMIN"
    ];
  };
}
