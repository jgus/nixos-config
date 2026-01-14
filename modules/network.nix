{ lib, machine, addresses, ... }:
let
  hostRecord = addresses.records.${machine.hostName};
in
{
  # Use systemd-networkd for network configuration
  # This provides native support for routing policy rules without oneshot service hacks
  networking = {
    hostName = machine.hostName;
    hostId = machine.hostId;
    useNetworkd = true;
    firewall = {
      allowPing = true;
      allowedTCPPorts = [ 5201 ]; # iperf
      allowedUDPPorts = [ 5201 ]; # iperf
    };
    useDHCP = false;
    tempAddresses = "disabled";
    domain = addresses.network.domain;
    nameservers = [ addresses.records.pihole-1.ip addresses.records.pihole-2.ip addresses.records.pihole-3.ip "1.1.1.1" "1.0.0.1" ];
    timeServers = [ "ntp.${addresses.network.domain}" ];
    hosts = addresses.hosts;
  };

  # systemd-networkd configuration
  systemd.network = {
    enable = true;

    # Create the br0 bridge device
    netdevs."00-br0" = lib.mkIf (machine ? lan-interfaces) {
      netdevConfig = {
        Kind = "bridge";
        Name = "br0";
      };
    };

    # Create the lan0 macvlan device on the effective LAN interface
    netdevs."10-lan0" = {
      netdevConfig = {
        Kind = "macvlan";
        Name = "lan0";
        MACAddress = hostRecord.mac;
      };
      macvlanConfig = {
        Mode = "bridge";
      };
    };

    # Configure each member interface to join the bridge
    networks."01-bridge-members" = lib.mkIf (machine ? lan-interfaces) {
      matchConfig.Name = lib.concatStringsSep " " machine.lan-interfaces;
      networkConfig = {
        Bridge = "br0";
        LinkLocalAddressing = "no";
      };
      linkConfig.RequiredForOnline = "enslaved";
    };

    # Configure the effective LAN interface (physical or bridge) to be the parent for macvlans
    networks."05-${machine.lan-interface}" = {
      matchConfig.Name = machine.lan-interface;
      networkConfig = {
        # Don't configure IP on this interface - only on macvlans
        LinkLocalAddressing = "no";
        DHCP = "no";
      };
      linkConfig.RequiredForOnline = "carrier";
      # Attach the lan0 macvlan
      macvlan = [ "lan0" ];
    };

    # Configure the lan0 macvlan interface (host's main interface)
    networks."20-lan0" = {
      matchConfig.Name = "lan0";
      networkConfig = {
        DHCP = "no";
        IPv6AcceptRA = "yes";
        LinkLocalAddressing = "ipv6";
      };
      linkConfig.RequiredForOnline = "routable";
      address = [
        "${hostRecord.ip}/${toString addresses.network.prefixLength}"
        "${hostRecord.ip6}/${toString addresses.network.prefix6Length}"
      ];
      gateway = [ addresses.network.defaultGateway ];
      # Routes in main table
      routes = [
        {
          Destination = "${addresses.network.prefix}0.0/${toString addresses.network.prefixLength}";
          Metric = 100;
        }
        {
          Destination = "${addresses.network.prefix6}/${toString addresses.network.prefix6Length}";
          Metric = 100;
        }
        # Routes in lan0 routing table (200) for source-based policy routing
        {
          Destination = "${addresses.network.prefix}0.0/${toString addresses.network.prefixLength}";
          Table = 200;
        }
        {
          Destination = "0.0.0.0/0";
          Gateway = addresses.network.defaultGateway;
          Table = 200;
        }
        {
          Destination = "${addresses.network.prefix6}/${toString addresses.network.prefix6Length}";
          Table = 200;
        }
      ];
      # Source-based policy routing rules
      routingPolicyRules = [
        {
          # Traffic FROM this host's IP uses the lan0 routing table
          From = hostRecord.ip;
          Table = 200;
          Priority = 100;
        }
        {
          # IPv6 rule
          From = hostRecord.ip6;
          Table = 200;
          Priority = 100;
        }
      ];
    };
  };

  # Boot kernel networking settings (related to ARP flux for macvlan)
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.arp_ignore" = 1; # Only respond if target IP is local address on receiving interface
    "net.ipv4.conf.all.arp_announce" = 2; # Use best local address for ARP requests
    "net.ipv4.conf.default.arp_ignore" = 1;
    "net.ipv4.conf.default.arp_announce" = 2;
  };
}
