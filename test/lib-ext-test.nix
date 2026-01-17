# Unit tests for lib-lib.ext.nix
with builtins;
{ lib }:
let
  testResults = lib.runTests {
    # test_fail = {
    #   expr = false;
    #   expected = true;
    # };

    # === IP Address Calculations ===
    test_router_ipv4 = {
      expr = lib.ext.nameToIp.router;
      expected = "172.22.0.1";
    };
    test_b1_ipv4 = {
      expr = lib.ext.nameToIp.b1;
      expected = "172.22.1.1";
    };
    test_c1_1_ipv4 = {
      expr = lib.ext.nameToIp."c1-1";
      expected = "172.22.1.2";
    };
    test_pihole_1_ipv4 = {
      expr = lib.ext.nameToIp.pihole-1;
      expected = "172.22.3.1";
    };

    # === MAC Address Calculations ===
    test_router_mac = {
      expr = lib.ext.nameToMac.router;
      expected = "d2:21:f9:d9:78:8c";
    };
    test_b1_mac = {
      expr = lib.ext.nameToMac.b1;
      expected = "00:24:0b:16:01:01";
    };

    # === IPv6 Calculations ===
    test_pihole_ipv6 = {
      expr = lib.ext.nameToIp6.pihole-1;
      expected = "2001:55d:b00b:1:224:bff:fe16:301";
    };

    # === Alias Resolution ===
    test_dns_alias = {
      expr = lib.ext.nameToIp.dns;
      expected = lib.ext.nameToIp.pihole-1;
    };
    test_dhcp_alias = {
      expr = lib.ext.nameToIp.dhcp;
      expected = lib.ext.nameToIp.pihole-1;
    };
    test_ha_alias = {
      expr = lib.ext.nameToIp.ha;
      expected = lib.ext.nameToIp."home-assistant";
    };
    test_pihole_host_alias = {
      expr = lib.ext.nameToIp."pihole-1-host";
      expected = lib.ext.nameToIp.b1;
    };

    # === Host Resolution ===
    test_pihole_host = {
      expr = lib.ext.nameToHost.pihole-1;
      expected = "b1";
    };
    test_plex_host = {
      expr = lib.ext.nameToHost.plex;
      expected = "d1";
    };
    test_samba_host = {
      expr = lib.ext.nameToHost.samba;
      expected = "c1-1";
    };

    # === ID Resolution ===
    test_b1_id_major = {
      expr = lib.ext.nameToIdMajor.b1;
      expected = 1;
    };
    test_b1_id_minor = {
      expr = lib.ext.nameToIdMinor.b1;
      expected = 1;
    };
    test_router_id_major = {
      expr = lib.ext.nameToIdMajor.router;
      expected = 0;
    };

    # === Server Names ===
    test_b1_is_server = {
      expr = elem "b1" lib.ext.serverNames;
      expected = true;
    };
    test_c1_1_is_server = {
      expr = elem "c1-1" lib.ext.serverNames;
      expected = true;
    };
    test_pihole_is_not_server = {
      expr = elem "pihole-1" lib.ext.serverNames;
      expected = false;
    };
    test_server_names_count = {
      expr = length lib.ext.serverNames;
      expected = 5;
    };

    # === IoT Records ===
    test_server_climate_ip = {
      expr = lib.ext.nameToIp."server-climate";
      expected = "172.21.1.20";
    };
    test_sprinklers_ip = {
      expr = lib.ext.nameToIp.sprinklers;
      expected = "172.21.2.30";
    };
    test_octoprint_ip = {
      expr = lib.ext.nameToIp.octoprint;
      expected = "172.21.31.8";
    };

    # === DHCP Reservations ===
    test_dhcp_reservations_non_empty = {
      expr = length lib.ext.dhcpReservations > 0;
      expected = true;
    };
    test_router_dhcp_reservation = {
      expr = any (r: r.name == "router") lib.ext.dhcpReservations;
      expected = true;
    };
    test_ap_balcony_dhcp_reservation = {
      expr = any (r: r.name == "ap-balcony") lib.ext.dhcpReservations;
      expected = true;
    };

    # === Container Options ===
    test_pihole_container_options_length = {
      expr = length (lib.ext.containerOptions "pihole-1");
      expected = 9;
    };
    test_container_options_has_macvlan = {
      expr = any (opt: substring 0 9 opt == "--network") (lib.ext.containerOptions "pihole-1");
      expected = true;
    };
    test_container_options_has_hostname = {
      expr = any (opt: substring 0 10 opt == "--hostname") (lib.ext.containerOptions "pihole-1");
      expected = true;
    };

    # === Container Add All Hosts ===
    test_container_add_all_hosts_non_empty = {
      expr = length lib.ext.containerAddAllHosts > 0;
      expected = true;
    };
    test_container_add_all_hosts_has_router = {
      expr = any (host: substring 0 18 host == "--add-host=router:") lib.ext.containerAddAllHosts;
      expected = true;
    };

    # === Hosts File Format ===
    test_hosts_has_router = {
      expr = hasAttr "172.22.0.1" lib.ext.hosts;
      expected = true;
    };
    test_router_hosts_includes_gateway = {
      expr = elem "gateway" lib.ext.hosts."172.22.0.1";
      expected = true;
    };
    test_router_hosts_includes_router = {
      expr = elem "router" lib.ext.hosts."172.22.0.1";
      expected = true;
    };
    test_router_hosts_includes_fqdn = {
      expr = elem "router.home.gustafson.me" lib.ext.hosts."172.22.0.1";
      expected = true;
    };
  };
in
lib.debug.throwTestFailures { failures = testResults; }
