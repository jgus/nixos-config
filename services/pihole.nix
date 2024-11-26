with builtins;
let
  name = "pihole";
  addresses = import ./../addresses.nix;
  pw = import ./../.secrets/passwords.nix;
in
{ config, pkgs, lib, ... }:
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
  dnsmasqConf = {
    dns = lib.concatStrings (map (ip: "host-record=" + (lib.concatStrings (map (s: "${s},") (getAttr ip addresses.hosts))) + ip + "\n") (attrNames addresses.hosts));
    dhcp = lib.concatStrings (map (r: "dhcp-host=" + r.mac + "," + r.ip + "," + r.name + ",infinite\n") addresses.dhcpReservations);
    config = ''
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
in
{
  docker = {
    image = "pihole/pihole";
    environment = {
      TZ = config.time.timeZone;
      WEBPASSWORD = pw.pihole;
      FTLCONF_LOCAL_IPV4 = addresses.records.${name}.ip;
      PIHOLE_DNS_ = "1.1.1.1;1.0.0.1;8.8.8.8;8.8.4.4;75.75.75.75;75.75.76.76";
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
    ]
    ++ (map (n: "${pkgs.writeText "50-nixos-${n}.conf" dnsmasqConf.${n}}:/etc/dnsmasq.d/50-nixos-${n}.conf") (attrNames dnsmasqConf))
    ++ (map (n: "${tftpFiles.${n}}:/tftp/${n}") (attrNames tftpFiles));
    extraOptions = [
      "--cap-add=NET_ADMIN"
    ];
  };
}
