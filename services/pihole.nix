with builtins;
let
  name = "pihole";
  addresses = import ./../addresses.nix;
  pw = import ./../.secrets/passwords.nix;
in
{ config, pkgs, ... }:
let
  tftpFiles = {
    "netboot.xyz.kpxe" = fetchurl {
      url = "https://github.com/netbootxyz/netboot.xyz/releases/download/2.0.81/netboot.xyz.kpxe";
      sha256 = "1dy6rnd70yycli0j0gzw0h2px0fvlr25b8df0ak9idy7ww26pmd6";
    };
    "netboot.xyz.efi" = fetchurl {
      url = "https://github.com/netbootxyz/netboot.xyz/releases/download/2.0.81/netboot.xyz.efi";
      sha256 = "0f7mmrv8yp6m8xzrlir04xf8nq7jmqfpkhaxacnjkiasjv07nryr";
    };
  };
  dhcpHosts = (map (r: r.mac + "," + r.ip + "," + r.name + ",infinite") addresses.dhcpReservations);
  dnsmasqConf = {
    config = ''
      dhcp-option=option:dns-server,${addresses.nameToIp.dns-1},${addresses.nameToIp.dns-2},${addresses.nameToIp.dns-3}
      dhcp-option=option:ntp-server,${addresses.nameToIp.ntp}

      enable-tftp
      tftp-root=/tftp
      # dhcp-boot=netboot.xyz.kpxe
      # pxe-service=x86PC,"NetBoot.xyz (BIOS)",netboot.xyz.kpxe
      # pxe-service=X86-64_EFI,"NetBoot.xyz (EFI)",netboot.xyz.efi
      dhcp-match=set:efi-x86_64,option:client-arch,7
      dhcp-match=set:efi-x86_64,option:client-arch,9
      dhcp-match=set:efi-x86,option:client-arch,6
      dhcp-match=set:bios,option:client-arch,0
      dhcp-boot=tag:efi-x86_64,netboot.xyz.efi
      dhcp-boot=tag:efi-x86,netboot.xyz.efi
      dhcp-boot=tag:bios,netboot.xyz.kpxe
    '';
  };
  upstream = [
    "1.1.1.1"
    "1.0.0.1"
    "8.8.8.8"
    "8.8.4.4"
    "75.75.75.75"
    "75.75.76.76"
  ];
in
map
  (n: {
    name = "pihole-${toString n}";
    docker = {
      image = "pihole/pihole";
      environment = {
        TZ = config.time.timeZone;
        FTLCONF_dns_upstreams = concatStringsSep ";" upstream;
        FTLCONF_dns_domainNeeded = "true";
        FTLCONF_dns_expandHosts = "true";
        FTLCONF_dns_domain = addresses.network.domain;
        FTLCONF_dns_dnssec = "true";
        FTLCONF_dns_interface = "eth0";
        FTLCONF_dns_listeningMode = "SINGLE";
        FTLCONF_dhcp_active = "true";
        FTLCONF_dhcp_start = "172.22.${toString (200+n)}.1";
        FTLCONF_dhcp_end = "172.22.${toString (200+n)}.254";
        FTLCONF_dhcp_router = addresses.network.defaultGateway;
        FTLCONF_dhcp_leaseTime = "24h";
        FTLCONF_dhcp_rapidCommit = "true";
        FTLCONF_dhcp_hosts = concatStringsSep ";" dhcpHosts;
        FTLCONF_ntp_ipv4_active = "false";
        FTLCONF_ntp_ipv6_active = "false";
        FTLCONF_ntp_sync_active = "false";
        FTLCONF_ntp_sync_server = "172.22.3.2";
        FTLCONF_webserver_api_password = pw.pihole;
        FTLCONF_misc_etc_dnsmasq_d = "true";
      };
      ports = [
        "53"
        "67/udp"
        "80/tcp"
        "443/tcp"
      ];
      configVolume = "/etc/pihole";
      volumes = storagePath: [
      ]
      ++ (map (n: "${pkgs.writeText "50-nixos-${n}.conf" dnsmasqConf.${n}}:/etc/dnsmasq.d/50-nixos-${n}.conf") (attrNames dnsmasqConf))
      ++ (map (n: "${tftpFiles.${n}}:/tftp/${n}") (attrNames tftpFiles));
      extraOptions = [
        "--cap-add=NET_ADMIN"
      ] ++ (map (x: "--dns=${x}") upstream);
    };
  }) [ 1 2 3 ]
