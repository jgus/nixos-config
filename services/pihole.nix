with builtins;
{ addresses, config, lib, pkgs, ... }:
let
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
  dhcpHosts = (map (r: r.mac + "," + r.ip + "," + r.name + ",infinite") lib.homelab.dhcpReservations);
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
        dhcp-option=option:dns-server,${lib.homelab.nameToIp.dns-1},${lib.homelab.nameToIp.dns-2},${lib.homelab.nameToIp.dns-3}
        dhcp-option=option:ntp-server,${lib.homelab.nameToIp.ntp}

        enable-tftp
        tftp-root=/tftp
        dhcp-match=set:bios,60,PXEClient:Arch:00000
        dhcp-boot=tag:bios,netboot.xyz.kpxe,,${lib.homelab.nameToIp.${name}}
        dhcp-match=set:efi32,60,PXEClient:Arch:00002
        dhcp-boot=tag:efi32,netboot.xyz.efi,,${lib.homelab.nameToIp.${name}}
        dhcp-match=set:efi32-1,60,PXEClient:Arch:00006
        dhcp-boot=tag:efi32-1,netboot.xyz.efi,,${lib.homelab.nameToIp.${name}}
        dhcp-match=set:efi64,60,PXEClient:Arch:00007
        dhcp-boot=tag:efi64,netboot.xyz.efi,,${lib.homelab.nameToIp.${name}}
        dhcp-match=set:efi64-1,60,PXEClient:Arch:00008
        dhcp-boot=tag:efi64-1,netboot.xyz.efi,,${lib.homelab.nameToIp.${name}}
        dhcp-match=set:efi64-2,60,PXEClient:Arch:00009
        dhcp-boot=tag:efi64-2,netboot.xyz.efi,,${lib.homelab.nameToIp.${name}}
      '';
    };
  in
  {
    inherit name;
    configStorage = false;
    container = {
      readOnly = false;
      pullImage = import ../images/pihole.nix;
      environment = {
        FTLCONF_dns_upstreams = concatStringsSep ";" upstream;
        FTLCONF_dns_domainNeeded = "true";
        FTLCONF_dns_expandHosts = "true";
        FTLCONF_dns_domain_name = addresses.network.domain;
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
        WEBPASSWORD_FILE = "WEBPASSWORD_FILE";
        FTLCONF_misc_etc_dnsmasq_d = "true";
      };
      ports = [
        "53"
        "67/udp"
        "80/tcp"
        "443/tcp"
      ];
      volumes = [
        "${config.sops.secrets.pihole.path}:/run/secrets/WEBPASSWORD_FILE:ro"
      ]
      ++ (map (n: "${pkgs.writeText "50-nixos-${n}.conf" dnsmasqConf.${n}}:/etc/dnsmasq.d/50-nixos-${n}.conf") (attrNames dnsmasqConf))
      ++ (map (n: "${tftpFiles.${n}}:/tftp/${n}") (attrNames tftpFiles));
      tmpFs = [
        "/etc/pihole"
      ];
      capabilities = {
        NET_ADMIN = true;
        NET_RAW = true;
        SYS_NICE = true;
      };
      extraOptions = [
        "--shm-size=1g"
      ]
      ++
      (map (x: "--dns=${x}") upstream)
      ++
      lib.homelab.containerAddAllHosts
      ;
    };
    extraConfig = {
      sops.secrets.pihole = { };
    };
  }) [ 1 2 3 ]
