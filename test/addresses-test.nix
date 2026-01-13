# Standalone unit test for settings/addresses.nix
# Run with: nix-instantiate --eval --expr 'import ./test/addresses-test.nix'
# Expected output: true

with builtins;

let
  lib = import <nixpkgs/lib>;

  # Import my-lib for macToIp6
  myLib = import ../my-lib.nix {
    inherit lib;
    pkgs = import <nixpkgs> { };
  };

  # Import the addresses module
  addresses = import ../settings/addresses.nix {
    inherit lib myLib;
  };

  # Import test-lib for assertion helpers
  testLib = import ./test-lib.nix {
    inherit lib;
    inherit myLib;
  };

  inherit (testLib) assertEq assertIn assertHasKey assertNotNull;

  # Test network configuration
  networkTests =
    assertEq "Network prefix" "172.22." addresses.network.prefix &&
    assertEq "Network prefix length" 16 addresses.network.prefixLength &&
    assertEq "Default gateway" "172.22.0.1" addresses.network.defaultGateway &&
    assertEq "IPv6 prefix" "2001:55d:b00b:1::" addresses.network.prefix6 &&
    assertEq "IPv6 prefix length" 64 addresses.network.prefix6Length &&
    assertEq "Domain" "home.gustafson.me" addresses.network.domain;

  # Test group configuration
  groupTests =
    assertEq "Group network ID" 0 addresses.group.network &&
    assertEq "Group servers ID" 1 addresses.group.servers &&
    assertEq "Group home-automation ID" 2 addresses.group.home-automation &&
    assertEq "Group services ID" 3 addresses.group.services &&
    assertEq "Group vms ID" 4 addresses.group.vms &&
    assertEq "Group admin ID" 5 addresses.group.admin &&
    assertEq "Group office ID" 31 addresses.group.office &&
    assertEq "Group study ID" 33 addresses.group.study;

  # Test records exist
  recordsExistTests =
    assertHasKey "router exists in records" "router" addresses.records &&
    assertHasKey "b1 exists in records" "b1" addresses.records &&
    assertHasKey "pihole-1 exists in records" "pihole-1" addresses.records;

  # Test IP calculations for sample records
  ipCalcTests =
    assertEq "router IPv4" "172.22.0.1" addresses.records.router.ip &&
    assertEq "router MAC" "d2:21:f9:d9:78:8c" addresses.records.router.mac &&
    assertEq "b1 IPv4" "172.22.1.1" addresses.records.b1.ip &&
    assertEq "b1 group" 1 addresses.records.b1.g &&
    assertEq "pihole-1 IPv4" "172.22.3.1" addresses.records.pihole-1.ip &&
    assertEq "pihole-1 host" "b1" addresses.records.pihole-1.host;

  # Test IPv6 calculation (pihole-1 uses host b1's MAC: group=1, id=1 -> generated MAC 00:24:0b:16:01:01)
  ipv6Tests =
    assertEq "pihole-1 IPv6" "2001:55d:b00b:1:224:bff:fe16:301" addresses.records.pihole-1.ip6;

  # Test nameToIp mappings
  nameToIpTests =
    assertHasKey "nameToIp has router" "router" addresses.nameToIp &&
    assertHasKey "nameToIp has b1" "b1" addresses.nameToIp &&
    assertEq "nameToIp for router" "172.22.0.1" addresses.nameToIp.router &&
    assertEq "nameToIp for b1" "172.22.1.1" addresses.nameToIp.b1 &&
    assertEq "nameToIp for c1-1" "172.22.1.2" addresses.nameToIp."c1-1";

  # Test nameToIp6 mappings
  nameToIp6Tests =
    assertHasKey "nameToIp6 has pihole-1" "pihole-1" addresses.nameToIp6 &&
    assertEq "nameToIp6 for pihole-1" "2001:55d:b00b:1:224:bff:fe16:301" addresses.nameToIp6."pihole-1";

  # Test alias resolution
  dnsAliasTests =
    assertHasKey "alias 'dns' resolves" "dns" addresses.nameToIp &&
    assertHasKey "alias 'dhcp' resolves" "dhcp" addresses.nameToIp &&
    assertEq "dns alias resolves to pihole-1" addresses.nameToIp."pihole-1" addresses.nameToIp.dns &&
    assertEq "dhcp alias resolves to pihole-1" addresses.nameToIp."pihole-1" addresses.nameToIp.dhcp &&
    assertEq "pihole-1-host alias resolves to b11" addresses.nameToIp."pihole-1-host" addresses.nameToIp.b1;

  # Test alias resolution for home-assistant
  haAliasTests =
    assertHasKey "alias 'ha' resolves" "ha" addresses.nameToIp &&
    assertEq "ha alias resolves to home-assistant" addresses.nameToIp."home-assistant" addresses.nameToIp.ha;

  # Test server names filtering
  serverNamesTests =
    assertIn "serverNames includes b1" "b1" addresses.serverNames &&
    assertIn "serverNames includes c1-1" "c1-1" addresses.serverNames &&
    assertIn "serverNames includes c1-2" "c1-2" addresses.serverNames &&
    assertIn "serverNames includes d1" "d1" addresses.serverNames &&
    assertEq "length of serverNames" 5 (length addresses.serverNames);

  # Test hosts file format (router has alias "gateway", so hosts include both)
  hostsTests =
    assertHasKey "hosts has router entry" addresses.nameToIp.router addresses.hosts &&
    assertIn "hosts for router includes gateway" "gateway" addresses.hosts.${addresses.nameToIp.router} &&
    assertIn "hosts for router includes router" "router" addresses.hosts.${addresses.nameToIp.router} &&
    assertIn "hosts for router includes gateway FQDN" "gateway.home.gustafson.me" addresses.hosts.${addresses.nameToIp.router} &&
    assertIn "hosts for router includes router FQDN" "router.home.gustafson.me" addresses.hosts.${addresses.nameToIp.router} &&
    assertHasKey "hosts6 has pihole-1 entry" addresses.nameToIp6."pihole-1" addresses.hosts &&
    assertIn "hosts6 for pihole-1 includes dhcp" "dhcp" addresses.hosts.${addresses.nameToIp6."pihole-1"} &&
    assertIn "hosts6 for pihole-1 includes pihole-1" "pihole-1" addresses.hosts.${addresses.nameToIp6."pihole-1"} &&
    assertIn "hosts6 for pihole-1 includes dhcp FQDN" "dhcp.home.gustafson.me" addresses.hosts.${addresses.nameToIp6."pihole-1"} &&
    assertIn "hosts6 for pihole-1 includes pihole-1 FQDN" "pihole-1.home.gustafson.me" addresses.hosts.${addresses.nameToIp6."pihole-1"};

  # Test DHCP reservations
  routerReservation = lib.findFirst (r: r.name == "router") null addresses.dhcpReservations;
  apBalconyReservation = lib.findFirst (r: r.name == "ap-balcony") null addresses.dhcpReservations;
  joshPcReservation = lib.findFirst (r: r.name == "josh-pc") null addresses.dhcpReservations;

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
  piholeOptions = addresses.containerOptions "pihole-1";
  plexOptions = addresses.containerOptions "plex";

  containerOptionsTests =
    assertEq "containerOptions has correct length" 9 (length piholeOptions) &&
    assertIn "containerOptions includes --network" "--network=macvlan" piholeOptions &&
    assertIn "containerOptions includes --mac-address" "--mac-address=${addresses.records.pihole-1.mac}" piholeOptions &&
    assertIn "containerOptions includes --hostname" "--hostname=pihole-1" piholeOptions &&
    assertIn "containerOptions includes --ip" "--ip=${addresses.records.pihole-1.ip}" piholeOptions &&
    assertIn "containerOptions includes --ip6" "--ip6=${addresses.records.pihole-1.ip6}" piholeOptions &&
    assertIn "containerOptions includes --dns-search" "--dns-search=home.gustafson.me" piholeOptions &&
    assertEq "plex containerOptions has correct --hostname" "--hostname=plex" (elemAt plexOptions 2) &&
    assertEq "plex containerOptions has correct --ip" "--ip=${addresses.records.plex.ip}" (elemAt plexOptions 3);

  # Test containerAddAllHosts
  routerHostEntry = lib.findFirst (s: lib.hasPrefix "--add-host=router:" s) null addresses.containerAddAllHosts;

  containerHostsTests =
    assertEq "containerAddAllHosts is non-empty" true (length addresses.containerAddAllHosts > 0) &&
    assertNotNull "containerAddAllHosts includes router" routerHostEntry;

  # Test IOT entries
  iotTests =
    assertEq "iot.server-climate has correct IP" "172.21.1.20" addresses.records."server-climate".ip &&
    assertEq "iot.sprinklers has correct IP" "172.21.2.30" addresses.records.sprinklers.ip &&
    assertEq "iot.octoprint has correct IP" "172.21.31.8" addresses.records.octoprint.ip;

  # Test pi-67cba1 entry
  theaterPi = addresses.records."pi-67cba1";

  theaterPiTests =
    assertEq "pi-67cba1 is in servers group" 1 theaterPi.g &&
    assertEq "pi-67cba1 ID" 65 theaterPi.id &&
    assertEq "pi-67cba1 IPv4" "172.22.1.65" theaterPi.ip;

  # Test home-assistant entry
  homeAssistant = addresses.records."home-assistant";

  haTests =
    assertEq "home-assistant host" "b1" homeAssistant.host &&
    assertEq "home-assistant ID" 30 homeAssistant.id &&
    assertEq "home-assistant has ha alias" true (lib.elem "ha" (homeAssistant.aliases or [ ])) &&
    assertEq "home-assistant has homeassistant alias" true (lib.elem "homeassistant" (homeAssistant.aliases or [ ]));

  # Test samba aliases
  sambaAliases = addresses.records.samba.aliases or [ ];

  sambaAliasTests =
    assertEq "samba has smb alias" true (lib.elem "smb" sambaAliases) &&
    assertEq "samba has nas alias" true (lib.elem "nas" sambaAliases) &&
    assertEq "smb alias resolves to samba" addresses.nameToIp.samba addresses.nameToIp.smb &&
    assertEq "nas alias resolves to samba" addresses.nameToIp.samba addresses.nameToIp.nas;

in
networkTests &&
groupTests &&
recordsExistTests &&
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
iotTests &&
theaterPiTests &&
haTests &&
sambaAliasTests
