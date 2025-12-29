with builtins;
{ config, lib, pkgs, ... }:
let
  addresses = import ./../addresses.nix { inherit lib; };
  pw = import ./../.secrets/passwords.nix;
  tftpFiles = {
    "netboot.xyz.kpxe" = fetchurl {
      url = "https://github.com/netbootxyz/netboot.xyz/releases/download/2.0.87/netboot.xyz.kpxe";
      sha256 = "115cacqv2k86wifzymqp1ndw5yx8wvmh2zll4dn2873wdvfxmlcl";
    };
    "netboot.xyz.efi" = fetchurl {
      url = "https://github.com/netbootxyz/netboot.xyz/releases/download/2.0.87/netboot.xyz.efi";
      sha256 = "0zqqq8d10gn9hy5rbxg5c46q8cjlmg6kv7gkwx3yabka53n7aizj";
    };
  };
  dhcpHosts = (map (r: r.mac + "," + r.ip + "," + r.name + ",infinite") addresses.dhcpReservations);
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
  (n:
  let
    name = "pihole-${toString n}";
    dnsmasqConf = {
      config = ''
        dhcp-option=option:dns-server,${addresses.nameToIp.dns-1},${addresses.nameToIp.dns-2},${addresses.nameToIp.dns-3}
        dhcp-option=option:ntp-server,${addresses.nameToIp.ntp}

        enable-tftp
        tftp-root=/tftp
        dhcp-match=set:bios,60,PXEClient:Arch:00000
        dhcp-boot=tag:bios,netboot.xyz.kpxe,,${addresses.nameToIp.${name}}
        dhcp-match=set:efi32,60,PXEClient:Arch:00002
        dhcp-boot=tag:efi32,netboot.xyz.efi,,${addresses.nameToIp.${name}}
        dhcp-match=set:efi32-1,60,PXEClient:Arch:00006
        dhcp-boot=tag:efi32-1,netboot.xyz.efi,,${addresses.nameToIp.${name}}
        dhcp-match=set:efi64,60,PXEClient:Arch:00007
        dhcp-boot=tag:efi64,netboot.xyz.efi,,${addresses.nameToIp.${name}}
        dhcp-match=set:efi64-1,60,PXEClient:Arch:00008
        dhcp-boot=tag:efi64-1,netboot.xyz.efi,,${addresses.nameToIp.${name}}
        dhcp-match=set:efi64-2,60,PXEClient:Arch:00009
        dhcp-boot=tag:efi64-2,netboot.xyz.efi,,${addresses.nameToIp.${name}}
      '';
    };
  in
  {
    inherit name;
    configStorage = false;
    container = {
      pullImage = {
        imageName = "pihole/pihole";
        imageDigest = "sha256:91dc91ddd413bf461c283204558f8f21839851e9824799075a7ceff7c77eea40";
        hash = "sha256-/+YRujV4n/ISyAD4LHBS1EnHwx4i6rahakbRaBIfSN0=";
        finalImageName = "pihole/pihole";
        finalImageTag = "latest";
      };
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
      # configVolume = "/etc/pihole";
      volumes = storagePath: [
      ]
      ++ (map (n: "${pkgs.writeText "50-nixos-${n}.conf" dnsmasqConf.${n}}:/etc/dnsmasq.d/50-nixos-${n}.conf") (attrNames dnsmasqConf))
      ++ (map (n: "${tftpFiles.${n}}:/tftp/${n}") (attrNames tftpFiles));
      extraOptions = [
        "--shm-size=1g"
        "--cap-add=NET_ADMIN"
        "--tmpfs=/etc/pihole"
      ]
      ++
      (map (x: "--dns=${x}") upstream)
      ++
      addresses.containerAddAllHosts
      ;
    };
  }) [ 1 2 3 ]
