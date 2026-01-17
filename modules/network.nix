{ addresses, lib, machine, ... }:
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
    nameservers = (map (n: lib.ext.nameToIp.${n}) addresses.network.dnsServers) ++ [ "1.1.1.1" "1.0.0.1" ];
    timeServers = [ "ntp.${addresses.network.domain}" ];
    hosts = lib.ext.hosts;
  };

  # systemd-networkd configuration
  systemd.network = lib.recursiveUpdate
    {
      enable = true;

      # Create the br0 bridge device
      netdevs."00-br0" = lib.mkIf (machine ? lan-interfaces) {
        netdevConfig = {
          Kind = "bridge";
          Name = "br0";
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
      };
    }
    # Configure the lan0 macvlan interface (host's main interface)
    (lib.ext.mkMacvlanSetup {
      hostName = machine.hostName;
      interfaceName = "lan0";
      netdevPriority = "10";
      networkPriority = "20";
      mainTableMetric = 100;
      policyTableId = 200;
      policyPriority = 100;
      requiredForOnline = "routable";
    });

  # Boot kernel networking settings (related to ARP flux for macvlan)
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.arp_ignore" = 1; # Only respond if target IP is local address on receiving interface
    "net.ipv4.conf.all.arp_announce" = 2; # Use best local address for ARP requests
    "net.ipv4.conf.default.arp_ignore" = 1;
    "net.ipv4.conf.default.arp_announce" = 2;
  };
}
