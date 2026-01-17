# Unit tests for lib-ext.nix
# Note: Many tests depend on hardcoded values from settings/addresses.nix
# If network configuration changes, these tests may need updating
with builtins;
{ lib }:
lib.debug.throwTestFailures {
  failures = lib.runTests rec {
    # test_fail = {
    #   expr = false;
    #   expected = true;
    # };

    # === nameToIp Tests ===
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

    # === nameToIp6 Tests ===
    test_pihole_ipv6 = {
      expr = lib.ext.nameToIp6.pihole-1;
      expected = "2001:55d:b00b:1:224:bff:fe16:301";
    };
    test_b1_ipv6 = {
      expr = lib.ext.nameToIp6.b1;
      expected = "2001:55d:b00b:1:224:bff:fe16:101";
    };
    test_c1_1_ipv6 = {
      expr = lib.ext.nameToIp6."c1-1";
      expected = "2001:55d:b00b:1:224:bff:fe16:102";
    };
    test_d1_ipv6 = {
      expr = lib.ext.nameToIp6.d1;
      expected = "2001:55d:b00b:1:224:bff:fe16:104";
    };
    test_router_ipv6 = {
      expr = lib.ext.nameToIp6.router;
      expected = "2001:55d:b00b:1:224:bff:fe16:1";
    };
    test_ipv6_alias_dns = {
      expr = lib.ext.nameToIp6.dns;
      expected = lib.ext.nameToIp6.pihole-1;
    };
    test_ipv6_alias_pihole = {
      expr = lib.ext.nameToIp6.pihole;
      expected = lib.ext.nameToIp6.pihole-1;
    };
    test_ipv6_alias_ha = {
      expr = lib.ext.nameToIp6.ha;
      expected = lib.ext.nameToIp6."home-assistant";
    };
    test_plex_ipv6 = {
      expr = lib.ext.nameToIp6.plex;
      expected = "2001:55d:b00b:1:224:bff:fe16:33c";
    };

    # === nameToMac Tests ===
    test_router_mac = {
      expr = lib.ext.nameToMac.router;
      expected = "d2:21:f9:d9:78:8c";
    };
    test_b1_mac = {
      expr = lib.ext.nameToMac.b1;
      expected = "00:24:0b:16:01:01";
    };
    test_c1_1_mac = {
      expr = lib.ext.nameToMac."c1-1";
      expected = "00:24:0b:16:01:02";
    };
    test_c1_2_mac = {
      expr = lib.ext.nameToMac."c1-2";
      expected = "00:24:0b:16:01:03";
    };
    test_d1_mac = {
      expr = lib.ext.nameToMac.d1;
      expected = "00:24:0b:16:01:04";
    };
    test_pihole_1_mac = {
      expr = lib.ext.nameToMac.pihole-1;
      expected = "00:24:0b:16:03:01";
    };
    test_mac_alias_dns = {
      expr = lib.ext.nameToMac.dns;
      expected = lib.ext.nameToMac.pihole-1;
    };
    test_mac_alias_dhcp = {
      expr = lib.ext.nameToMac.dhcp;
      expected = lib.ext.nameToMac.pihole-1;
    };
    test_mac_alias_mqtt = {
      expr = lib.ext.nameToMac.mqtt;
      expected = lib.ext.nameToMac.mosquitto;
    };

    # === nameToHost Tests ===
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

    # === nameToIdMajor Tests ===
    test_b1_id_major = {
      expr = lib.ext.nameToIdMajor.b1;
      expected = 1;
    };
    test_router_id_major = {
      expr = lib.ext.nameToIdMajor.router;
      expected = 0;
    };

    # === nameToIdMinor Tests ===
    test_b1_id_minor = {
      expr = lib.ext.nameToIdMinor.b1;
      expected = 1;
    };
    test_c1_1_id_minor = {
      expr = lib.ext.nameToIdMinor."c1-1";
      expected = 2;
    };
    test_c1_2_id_minor = {
      expr = lib.ext.nameToIdMinor."c1-2";
      expected = 3;
    };
    test_d1_id_minor = {
      expr = lib.ext.nameToIdMinor.d1;
      expected = 4;
    };
    test_pihole_1_id_minor = {
      expr = lib.ext.nameToIdMinor.pihole-1;
      expected = 1;
    };
    test_router_id_minor = {
      expr = lib.ext.nameToIdMinor.router;
      expected = 1;
    };

    # === serverNames Tests ===
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

    # === dhcpReservations Tests ===
    hasReservationWithName = name: any (r: r.name == name) lib.ext.dhcpReservations;
    hasReservationWithMac = mac: any (r: r.mac == mac) lib.ext.dhcpReservations;
    hasReservationWithIp = ip: any (r: r.ip == ip) lib.ext.dhcpReservations;
    test_dhcp_reservations_non_empty = {
      expr = length lib.ext.dhcpReservations > 0;
      expected = true;
    };
    test_router_dhcp_reservation = {
      expr = hasReservationWithName "router";
      expected = true;
    };
    test_ap_balcony_dhcp_reservation = {
      expr = hasReservationWithName "ap-balcony";
      expected = true;
    };
    test_dhcp_reservation_router_mac = {
      expr = hasReservationWithMac "d2:21:f9:d9:78:8c";
      expected = true;
    };
    test_dhcp_reservation_router_ip = {
      expr = hasReservationWithIp "172.22.0.1";
      expected = true;
    };
    test_iot_not_in_dhcp_reservations = {
      expr = hasReservationWithName "server-climate";
      expected = false;
    };

    # === containerOptions Tests ===
    hasContainerOption = service: opt: elem opt (lib.ext.containerOptions service);
    test_pihole_container_options_length = {
      expr = length (lib.ext.containerOptions "pihole-1");
      expected = 9;
    };
    test_container_options_has_macvlan = {
      expr = hasContainerOption "pihole-1" "--network=macvlan";
      expected = true;
    };
    test_container_options_has_hostname = {
      expr = hasContainerOption "pihole-1" "--hostname=pihole-1";
      expected = true;
    };
    test_container_options_mac_address = {
      expr = hasContainerOption "pihole-1" "--mac-address=00:24:0b:16:03:01";
      expected = true;
    };
    test_container_options_ip = {
      expr = hasContainerOption "pihole-1" "--ip=172.22.3.1";
      expected = true;
    };
    test_container_options_ip6 = {
      expr = any (opt: lib.strings.hasPrefix "--ip6" opt) (lib.ext.containerOptions "pihole-1");
      expected = true;
    };
    test_container_options_dns_servers = {
      expr = hasContainerOption "pihole-1" "--dns=172.22.3.1";
      expected = true;
    };
    test_container_options_dns_search = {
      expr = hasContainerOption "pihole-1" "--dns-search=home.gustafson.me";
      expected = true;
    };
    test_plex_container_options = {
      expr = length (lib.ext.containerOptions "plex");
      expected = 9;
    };

    # === containerAddAllHosts Tests ===
    test_container_add_all_hosts_non_empty = {
      expr = length lib.ext.containerAddAllHosts > 0;
      expected = true;
    };
    test_container_add_all_hosts_has_router = {
      expr = any (host: lib.strings.hasPrefix "--add-host=router:" host) lib.ext.containerAddAllHosts;
      expected = true;
    };

    # === hosts Tests ===
    hasHostEntry = ip: name: elem name (lib.ext.hosts.${ip} or [ ]);
    test_hosts_has_router = {
      expr = hasAttr "172.22.0.1" lib.ext.hosts;
      expected = true;
    };
    test_router_hosts_includes_gateway = {
      expr = hasHostEntry "172.22.0.1" "gateway";
      expected = true;
    };
    test_router_hosts_includes_router = {
      expr = hasHostEntry "172.22.0.1" "router";
      expected = true;
    };
    test_router_hosts_includes_fqdn = {
      expr = hasHostEntry "172.22.0.1" "router.home.gustafson.me";
      expected = true;
    };
    test_hosts_multiple_names_same_ip = {
      expr = hasHostEntry "172.22.3.1" "pihole-1";
      expected = true;
    };
    test_hosts_multiple_aliases_same_ip = {
      expr = hasHostEntry "172.22.3.1" "dns";
      expected = true;
    };
    test_hosts_fqdn_pihole = {
      expr = hasHostEntry "172.22.3.1" "pihole-1.home.gustafson.me";
      expected = true;
    };
    test_hosts_iot_device = {
      expr = hasAttr "172.21.1.20" lib.ext.hosts;
      expected = true;
    };
    test_hosts_iot_device_name = {
      expr = hasHostEntry "172.21.1.20" "server-climate";
      expected = true;
    };

    # === Formatting Functions Tests ===
    test_toDebugStr_string = {
      expr = lib.ext.toDebugStr "hello";
      expected = "hello";
    };
    test_toDebugInt = {
      expr = lib.ext.toDebugStr 42;
      expected = "42";
    };
    test_toDebugStr_list = {
      expr = lib.ext.toDebugStr [ "a" "b" "c" ];
      expected = ''["a","b","c"]'';
    };
    test_toDebugStr_attrs = {
      expr = lib.ext.toDebugStr { foo = "bar"; };
      expected = ''{"foo":"bar"}'';
    };
    test_toDebugStr_boolean_true = {
      expr = lib.ext.toDebugStr true;
      expected = "1";
    };
    test_toDebugStr_boolean_false = {
      expr = lib.ext.toDebugStr false;
      expected = "";
    };
    test_toDebugStr_null = {
      expr = lib.ext.toDebugStr null;
      expected = "";
    };
    test_toDebugStr_empty_list = {
      expr = lib.ext.toDebugStr [ ];
      expected = ''[]'';
    };
    test_toDebugStr_empty_attrs = {
      expr = lib.ext.toDebugStr { };
      expected = ''{}'';
    };
    test_toDebugStr_nested_attrs = {
      expr = lib.ext.toDebugStr { outer = { inner = "value"; }; };
      expected = ''{"outer":{"inner":"value"}}'';
    };
    test_toDebugStr_nested_lists = {
      expr = lib.ext.toDebugStr [ [ "a" "b" ] [ "c" "d" ] ];
      expected = ''[["a","b"],["c","d"]]'';
    };
    test_toDebugStr_mixed_nested = {
      expr = lib.ext.toDebugStr { list = [ 1 2 ]; nested = { a = { b = "c"; }; }; };
      expected = ''{"list":[1,2],"nested":{"a":{"b":"c"}}}'';
    };

    # === pretty* Tests ===
    test_prettyJson_simple = {
      expr = fromJSON (readFile (lib.ext.prettyJson { foo = "bar"; }));
      expected = { foo = "bar"; };
    };
    test_prettyJson_nested = {
      expr = fromJSON (readFile (lib.ext.prettyJson { items = [ 1 2 3 ]; nested = { a = "b"; }; }));
      expected = { items = [ 1 2 3 ]; nested = { a = "b"; }; };
    };
    test_prettyJson_numbers = {
      expr = fromJSON (readFile (lib.ext.prettyJson { count = 42; pi = 3.14; }));
      expected = { count = 42; pi = 3.14; };
    };
    test_prettyToml_simple = {
      expr = fromTOML (readFile (lib.ext.prettyToml { foo = "bar"; }));
      expected = { foo = "bar"; };
    };
    test_prettyToml_nested = {
      expr = fromTOML (readFile (lib.ext.prettyToml { items = [ 1 2 3 ]; nested = { a = "b"; }; }));
      expected = { items = [ 1 2 3 ]; nested = { a = "b"; }; };
    };
    test_prettyToml_numbers = {
      expr = fromTOML (readFile (lib.ext.prettyToml { count = 42; pi = 3.14; }));
      expected = { count = 42; pi = 3.14; };
    };
    # TODO: prettyYaml
    # TODO: prettyXml

    # === mkMacvlanSetup Tests ===
    b1MacvlanSetup = (lib.ext.mkMacvlanSetup {
      hostName = "b1";
      interfaceName = "mv-test";
      netdevPriority = "10";
      networkPriority = "20";
      mainTableMetric = 100;
      policyTableId = 100;
      policyPriority = 1000;
    });
    test_mkMacvlanSetup_returns_netdev = {
      expr = b1MacvlanSetup.netdevs ? "10-mv-test";
      expected = true;
    };
    test_mkMacvlanSetup_netdev_kind = {
      expr = b1MacvlanSetup.netdevs."10-mv-test".netdevConfig.Kind;
      expected = "macvlan";
    };
    test_mkMacvlanSetup_netdev_name = {
      expr = b1MacvlanSetup.netdevs."10-mv-test".netdevConfig.Name;
      expected = "mv-test";
    };
    test_mkMacvlanSetup_netdev_mac = {
      expr = b1MacvlanSetup.netdevs."10-mv-test".netdevConfig.MACAddress;
      expected = "00:24:0b:16:01:01";
    };
    test_mkMacvlanSetup_macvlan_mode = {
      expr = b1MacvlanSetup.netdevs."10-mv-test".macvlanConfig.Mode;
      expected = "bridge";
    };
    test_mkMacvlanSetup_returns_network = {
      expr = b1MacvlanSetup.networks ? "20-mv-test";
      expected = true;
    };
    test_mkMacvlanSetup_network_match_name = {
      expr = b1MacvlanSetup.networks."20-mv-test".matchConfig.Name;
      expected = "mv-test";
    };
    test_mkMacvlanSetup_network_dhcp_disabled = {
      expr = b1MacvlanSetup.networks."20-mv-test".networkConfig.DHCP;
      expected = "no";
    };
    test_mkMacvlanSetup_network_ipv6_accept_ra = {
      expr = b1MacvlanSetup.networks."20-mv-test".networkConfig.IPv6AcceptRA;
      expected = "yes";
    };
    test_mkMacvlanSetup_has_ipv4_address = {
      expr = b1MacvlanSetup.networks."20-mv-test".addresses != [ ];
      expected = true;
    };
    test_mkMacvlanSetup_has_ipv6_address = {
      expr = length b1MacvlanSetup.networks."20-mv-test".addresses;
      expected = 2;
    };
    test_mkMacvlanSetup_has_routes = {
      expr = b1MacvlanSetup.networks."20-mv-test".routes != [ ];
      expected = true;
    };
    test_mkMacvlanSetup_has_routing_policy_rules = {
      expr = b1MacvlanSetup.networks."20-mv-test".routingPolicyRules != [ ];
      expected = true;
    };
    test_mkMacvlanSetup_routing_policy_rule_count = {
      expr = length b1MacvlanSetup.networks."20-mv-test".routingPolicyRules;
      expected = 2;
    };
    test_mkMacvlanSetup_default_route = {
      expr = b1MacvlanSetup.networks."20-mv-test".gateway;
      expected = [ "172.22.0.1" ];
    };
    test_mkMacvlanSetup_AddPrefixRoute_default = {
      expr = (elemAt
        b1MacvlanSetup.networks."20-mv-test".addresses
        1).AddPrefixRoute;
      expected = true;
    };
    test_mkMacvlanSetup_requiredForOnline_default = {
      expr = b1MacvlanSetup.networks."20-mv-test".linkConfig.RequiredForOnline;
      expected = "no";
    };

    c1_1MacvlanSetup = (lib.ext.mkMacvlanSetup {
      hostName = "c1-1";
      interfaceName = "mv-test";
      netdevPriority = "10";
      networkPriority = "20";
      mainTableMetric = 100;
      policyTableId = 100;
      policyPriority = 1000;
    });
    test_mkMacvlanSetup_c1_1_mac = {
      expr = c1_1MacvlanSetup.netdevs."10-mv-test".netdevConfig.MACAddress;
      expected = "00:24:0b:16:01:02";
    };
  };
}
