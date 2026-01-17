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

  myLib = import ../my-lib.nix {
    inherit lib addresses machine pkgs;
  };

  testLib = import ./test-lib.nix {
    inherit lib myLib;
  };

  inherit (testLib) assertEq assertIn assertHasKey assertNotNull;

  # Test IP calculations for sample records
  ipCalcTests =
    assertEq "router IPv4" "172.22.0.1" myLib.nameToIp.router &&
    assertEq "router MAC" "d2:21:f9:d9:78:8c" myLib.nameToMac.router &&
    assertEq "b1 IPv4" "172.22.1.1" myLib.nameToIp.b1 &&
    assertEq "b1 group" 1 myLib.nameToIdMajor.b1 &&
    assertEq "pihole-1 IPv4" "172.22.3.1" myLib.nameToIp.pihole-1 &&
    assertEq "pihole-1 host" "b1" myLib.nameToHost.pihole-1;

  # Test IPv6 calculation (pihole-1 uses host b1's MAC: group=1, id=1 -> generated MAC 00:24:0b:16:01:01)
  ipv6Tests =
    assertEq "pihole-1 IPv6" "2001:55d:b00b:1:224:bff:fe16:301" myLib.nameToIp6.pihole-1;

  # Test nameToIp mappings
  nameToIpTests =
    assertHasKey "nameToIp has router" "router" myLib.nameToIp &&
    assertHasKey "nameToIp has b1" "b1" myLib.nameToIp &&
    assertEq "nameToIp for router" "172.22.0.1" myLib.nameToIp.router &&
    assertEq "nameToIp for b1" "172.22.1.1" myLib.nameToIp.b1 &&
    assertEq "nameToIp for c1-1" "172.22.1.2" myLib.nameToIp."c1-1";

  # Test nameToIp6 mappings
  nameToIp6Tests =
    assertHasKey "nameToIp6 has pihole-1" "pihole-1" myLib.nameToIp6 &&
    assertEq "nameToIp6 for pihole-1" "2001:55d:b00b:1:224:bff:fe16:301" myLib.nameToIp6."pihole-1";

  # Test alias resolution
  dnsAliasTests =
    assertHasKey "alias 'dns' resolves" "dns" myLib.nameToIp &&
    assertHasKey "alias 'dhcp' resolves" "dhcp" myLib.nameToIp &&
    assertEq "dns alias resolves to pihole-1" myLib.nameToIp."pihole-1" myLib.nameToIp.dns &&
    assertEq "dhcp alias resolves to pihole-1" myLib.nameToIp."pihole-1" myLib.nameToIp.dhcp &&
    assertEq "pihole-1-host alias resolves to b11" myLib.nameToIp."pihole-1-host" myLib.nameToIp.b1;

  # Test alias resolution for home-assistant
  haAliasTests =
    assertHasKey "alias 'ha' resolves" "ha" myLib.nameToIp &&
    assertEq "ha alias resolves to home-assistant" myLib.nameToIp."home-assistant" myLib.nameToIp.ha;

  # Test server names filtering
  serverNamesTests =
    assertIn "serverNames includes b1" "b1" myLib.serverNames &&
    assertIn "serverNames includes c1-1" "c1-1" myLib.serverNames &&
    assertIn "serverNames includes c1-2" "c1-2" myLib.serverNames &&
    assertIn "serverNames includes d1" "d1" myLib.serverNames &&
    assertEq "length of serverNames" 5 (length myLib.serverNames);

  # Test hosts file format (router has alias "gateway", so hosts include both)
  hostsTests =
    assertHasKey "hosts has router entry" myLib.nameToIp.router myLib.hosts &&
    assertIn "hosts for router includes gateway" "gateway" myLib.hosts.${myLib.nameToIp.router} &&
    assertIn "hosts for router includes router" "router" myLib.hosts.${myLib.nameToIp.router} &&
    assertIn "hosts for router includes gateway FQDN" "gateway.${addresses.network.domain}" myLib.hosts.${myLib.nameToIp.router} &&
    assertIn "hosts for router includes router FQDN" "router.${addresses.network.domain}" myLib.hosts.${myLib.nameToIp.router} &&
    assertHasKey "hosts6 has pihole-1 entry" myLib.nameToIp6."pihole-1" myLib.hosts &&
    assertIn "hosts6 for pihole-1 includes dhcp" "dhcp" myLib.hosts.${myLib.nameToIp6."pihole-1"} &&
    assertIn "hosts6 for pihole-1 includes pihole-1" "pihole-1" myLib.hosts.${myLib.nameToIp6."pihole-1"} &&
    assertIn "hosts6 for pihole-1 includes dhcp FQDN" "dhcp.${addresses.network.domain}" myLib.hosts.${myLib.nameToIp6."pihole-1"} &&
    assertIn "hosts6 for pihole-1 includes pihole-1 FQDN" "pihole-1.${addresses.network.domain}" myLib.hosts.${myLib.nameToIp6."pihole-1"};

  # Test DHCP reservations
  routerReservation = lib.findFirst (r: r.name == "router") null myLib.dhcpReservations;
  apBalconyReservation = lib.findFirst (r: r.name == "ap-balcony") null myLib.dhcpReservations;
  joshPcReservation = lib.findFirst (r: r.name == "josh-pc") null myLib.dhcpReservations;

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
  piholeOptions = myLib.containerOptions "pihole-1";
  plexOptions = myLib.containerOptions "plex";

  containerOptionsTests =
    assertEq "containerOptions has correct length" 9 (length piholeOptions) &&
    assertIn "containerOptions includes --network" "--network=macvlan" piholeOptions &&
    assertIn "containerOptions includes --mac-address" "--mac-address=${myLib.nameToMac.pihole-1}" piholeOptions &&
    assertIn "containerOptions includes --hostname" "--hostname=pihole-1" piholeOptions &&
    assertIn "containerOptions includes --ip" "--ip=${myLib.nameToIp.pihole-1}" piholeOptions &&
    assertIn "containerOptions includes --ip6" "--ip6=${myLib.nameToIp6.pihole-1}" piholeOptions &&
    assertIn "containerOptions includes --dns-search" "--dns-search=${addresses.network.domain}" piholeOptions &&
    assertEq "plex containerOptions has correct --hostname" "--hostname=plex" (elemAt plexOptions 2) &&
    assertEq "plex containerOptions has correct --ip" "--ip=${myLib.nameToIp.plex}" (elemAt plexOptions 3);

  # Test containerAddAllHosts
  routerHostEntry = lib.findFirst (s: lib.hasPrefix "--add-host=router:" s) null myLib.containerAddAllHosts;

  containerHostsTests =
    assertEq "containerAddAllHosts is non-empty" true (length myLib.containerAddAllHosts > 0) &&
    assertNotNull "containerAddAllHosts includes router" routerHostEntry;

  # Test IOT entries
  iotTests =
    assertEq "iot.server-climate has correct IP" "172.21.1.20" myLib.nameToIp."server-climate" &&
    assertEq "iot.sprinklers has correct IP" "172.21.2.30" myLib.nameToIp.sprinklers &&
    assertEq "iot.octoprint has correct IP" "172.21.31.8" myLib.nameToIp.octoprint;

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
