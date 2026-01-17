# Standalone unit test for settings/addresses.nix
# Run with: nix-instantiate --eval --expr 'import ./test/addresses-test.nix'
# Expected output: true

with builtins;

let
  flake = builtins.getFlake (toString ../.);
  nixos-extra-modules = flake.inputs.nixos-extra-modules;

  machine = import ../settings/machine.nix { machineId = "b1"; lib = flake.inputs.nixpkgs.lib; };

  pkgs = import flake.inputs.nixpkgs {
    inherit (machine) system;
    overlays = [ nixos-extra-modules.overlays.default ];
  };

  lib = pkgs.lib;

  addresses = import ../settings/addresses.nix { inherit lib; };

  lib.ext = import ../my-lib.nix {
    inherit lib addresses machine pkgs;
  };

  testLib = import ./test-lib.nix {
    inherit lib lib. ext;
  };

  inherit (testLib) assertEq assertIn assertHasKey assertNotNull;

  # Test IP calculations for sample records
  ipCalcTests =
    assertEq "router IPv4" "172.22.0.1" lib.ext.nameToIp.router &&
    assertEq "router MAC" "d2:21:f9:d9:78:8c" lib.ext.nameToMac.router &&
    assertEq "b1 IPv4" "172.22.1.1" lib.ext.nameToIp.b1 &&
    assertEq "b1 group" 1 lib.ext.nameToIdMajor.b1 &&
    assertEq "pihole-1 IPv4" "172.22.3.1" lib.ext.nameToIp.pihole-1 &&
    assertEq "pihole-1 host" "b1" lib.ext.nameToHost.pihole-1;

  # Test IPv6 calculation (pihole-1 uses host b1's MAC: group=1, id=1 -> generated MAC 00:24:0b:16:01:01)
  ipv6Tests =
    assertEq "pihole-1 IPv6" "2001:55d:b00b:1:224:bff:fe16:301" lib.ext.nameToIp6.pihole-1;

  # Test nameToIp mappings
  nameToIpTests =
    assertHasKey "nameToIp has router" "router" lib.ext.nameToIp &&
    assertHasKey "nameToIp has b1" "b1" lib.ext.nameToIp &&
    assertEq "nameToIp for router" "172.22.0.1" lib.ext.nameToIp.router &&
    assertEq "nameToIp for b1" "172.22.1.1" lib.ext.nameToIp.b1 &&
    assertEq "nameToIp for c1-1" "172.22.1.2" lib.ext.nameToIp."c1-1";

  # Test nameToIp6 mappings
  nameToIp6Tests =
    assertHasKey "nameToIp6 has pihole-1" "pihole-1" lib.ext.nameToIp6 &&
    assertEq "nameToIp6 for pihole-1" "2001:55d:b00b:1:224:bff:fe16:301" lib.ext.nameToIp6."pihole-1";

  # Test alias resolution
  dnsAliasTests =
    assertHasKey "alias 'dns' resolves" "dns" lib.ext.nameToIp &&
    assertHasKey "alias 'dhcp' resolves" "dhcp" lib.ext.nameToIp &&
    assertEq "dns alias resolves to pihole-1" lib.ext.nameToIp."pihole-1" lib.ext.nameToIp.dns &&
    assertEq "dhcp alias resolves to pihole-1" lib.ext.nameToIp."pihole-1" lib.ext.nameToIp.dhcp &&
    assertEq "pihole-1-host alias resolves to b11" lib.ext.nameToIp."pihole-1-host" lib.ext.nameToIp.b1;

  # Test alias resolution for home-assistant
  haAliasTests =
    assertHasKey "alias 'ha' resolves" "ha" lib.ext.nameToIp &&
    assertEq "ha alias resolves to home-assistant" lib.ext.nameToIp."home-assistant" lib.ext.nameToIp.ha;

  # Test server names filtering
  serverNamesTests =
    assertIn "serverNames includes b1" "b1" lib.ext.serverNames &&
    assertIn "serverNames includes c1-1" "c1-1" lib.ext.serverNames &&
    assertIn "serverNames includes c1-2" "c1-2" lib.ext.serverNames &&
    assertIn "serverNames includes d1" "d1" lib.ext.serverNames &&
    assertEq "length of serverNames" 5 (length lib.ext.serverNames);

  # Test hosts file format (router has alias "gateway", so hosts include both)
  hostsTests =
    assertHasKey "hosts has router entry" lib.ext.nameToIp.router lib.ext.hosts &&
    assertIn "hosts for router includes gateway" "gateway" lib.ext.hosts.${lib.ext.nameToIp.router} &&
    assertIn "hosts for router includes router" "router" lib.ext.hosts.${lib.ext.nameToIp.router} &&
    assertIn "hosts for router includes gateway FQDN" "gateway.${addresses.network.domain}" lib.ext.hosts.${lib.ext.nameToIp.router} &&
    assertIn "hosts for router includes router FQDN" "router.${addresses.network.domain}" lib.ext.hosts.${lib.ext.nameToIp.router} &&
    assertHasKey "hosts6 has pihole-1 entry" lib.ext.nameToIp6."pihole-1" lib.ext.hosts &&
    assertIn "hosts6 for pihole-1 includes dhcp" "dhcp" lib.ext.hosts.${lib.ext.nameToIp6."pihole-1"} &&
    assertIn "hosts6 for pihole-1 includes pihole-1" "pihole-1" lib.ext.hosts.${lib.ext.nameToIp6."pihole-1"} &&
    assertIn "hosts6 for pihole-1 includes dhcp FQDN" "dhcp.${addresses.network.domain}" lib.ext.hosts.${lib.ext.nameToIp6."pihole-1"} &&
    assertIn "hosts6 for pihole-1 includes pihole-1 FQDN" "pihole-1.${addresses.network.domain}" lib.ext.hosts.${lib.ext.nameToIp6."pihole-1"};

  # Test DHCP reservations
  routerReservation = lib.findFirst (r: r.name == "router") null lib.ext.dhcpReservations;
  apBalconyReservation = lib.findFirst (r: r.name == "ap-balcony") null lib.ext.dhcpReservations;
  joshPcReservation = lib.findFirst (r: r.name == "josh-pc") null lib.ext.dhcpReservations;

  dhcpTests =
    assertNotNull "DHCP reservation for router exists" routerReservation &&
    assertEq "DHCP reservation router IP" "172.22.0.1" routerReservation.ip &&
    assertEq "DHCP reservation router MAC" "d2:21:f9:d9:78:8c" routerReservation.mac &&
    assertNotNull "DHCP reservation for ap-balcony exists" apBalconyReservation &&
    assertEq "DHCP reservation ap-balcony IP" "172.22.0.10" apBalconyReservation.ip &&
    assertEq "DHCP reservation ap-balcony MAC" "ac:8b:a9:69:2a:ea" apBalconyReservation.mac &&
    assertNotNull "DHCP reservation for josh-pc exists" joshPcReservation &&
    assertEq "DHCP reservation josh-pc IP" "172.22.31.1" joshPcReservation.ip &&
    assertEq "DHCP reservation josh-pc MAC" "3c:fd:fe:e1:b9:d6" joshPcReservation.mac;

  # Test container options (9 elements: network, mac, hostname, ip, ip6, 3x dns, dns-search)
  piholeOptions = lib.ext.containerOptions "pihole-1";
  plexOptions = lib.ext.containerOptions "plex";

  containerOptionsTests =
    assertEq "containerOptions has correct length" 9 (length piholeOptions) &&
    assertIn "containerOptions includes --network" "--network=macvlan" piholeOptions &&
    assertIn "containerOptions includes --mac-address" "--mac-address=${lib.ext.nameToMac.pihole-1}" piholeOptions &&
    assertIn "containerOptions includes --hostname" "--hostname=pihole-1" piholeOptions &&
    assertIn "containerOptions includes --ip" "--ip=${lib.ext.nameToIp.pihole-1}" piholeOptions &&
    assertIn "containerOptions includes --ip6" "--ip6=${lib.ext.nameToIp6.pihole-1}" piholeOptions &&
    assertIn "containerOptions includes --dns-search" "--dns-search=${addresses.network.domain}" piholeOptions &&
    assertEq "plex containerOptions has correct --hostname" "--hostname=plex" (elemAt plexOptions 2) &&
    assertEq "plex containerOptions has correct --ip" "--ip=${lib.ext.nameToIp.plex}" (elemAt plexOptions 3);

  # Test containerAddAllHosts
  routerHostEntry = lib.findFirst (s: lib.hasPrefix "--add-host=router:" s) null lib.ext.containerAddAllHosts;

  containerHostsTests =
    assertEq "containerAddAllHosts is non-empty" true (length lib.ext.containerAddAllHosts > 0) &&
    assertNotNull "containerAddAllHosts includes router" routerHostEntry;

  # Test IOT entries
  iotTests =
    assertEq "iot.server-climate has correct IP" "172.21.1.20" lib.ext.nameToIp."server-climate" &&
    assertEq "iot.sprinklers has correct IP" "172.21.2.30" lib.ext.nameToIp.sprinklers &&
    assertEq "iot.octoprint has correct IP" "172.21.31.8" lib.ext.nameToIp.octoprint;

in
ipCalcTests &&
ipv6Tests &&
nameToIpTests &&
nameToIp6Tests &&
dnsAliasTests &&
haAliasTests &&
serverNamesTests &&
hostsTests &&
dhcpTests &&
containerOptionsTests &&
containerHostsTests &&
iotTests
