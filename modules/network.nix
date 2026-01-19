with builtins;
{ addresses, lib, machine, ... }:
{
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

  systemd.network = lib.ext.recursiveUpdates [
    # Base Config
    {
      enable = true;

      # Create the br0 bridge device for all physical interfaces
      netdevs."00-br0" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "br0";
        };
        bridgeConfig = {
          VLANFiltering = true;
          DefaultPVID = 1;
        };
      };

      # Configure each member interface to join the bridge with VLANs
      networks."01-bridge-members" = {
        matchConfig.Name = lib.concatStringsSep " " machine.lan-interfaces;
        networkConfig = {
          Bridge = "br0";
          LinkLocalAddressing = "no";
        };
        linkConfig.RequiredForOnline = "enslaved";
        # Configure VLANs: VLAN 1 (untagged, PVID) plus all VLANs from addresses.vlans
        bridgeVLANs =
          # VLAN 1 as PVID and untagged
          [{ VLAN = 1; PVID = 1; EgressUntagged = 1; }] ++
          # All other VLANs as tagged
          (map (vlan: { VLAN = vlan.vlanId; }) (attrValues addresses.vlans));
      };

      # Configure the effective LAN interface (physical or bridge) to be the parent for macvlans
      networks."05-br0" = {
        matchConfig.Name = "br0";
        networkConfig = {
          # Don't configure IP on this interface - only on macvlans
          LinkLocalAddressing = "no";
          DHCP = "no";
        };
        vlan = (map (vlan: "br0.${toString vlan.vlanId}") (attrValues addresses.vlans));
        linkConfig.RequiredForOnline = "carrier";
      };
    }

    # VLANs
    {
      netdevs = lib.mapAttrs'
        (name: vlan:
          lib.nameValuePair "02-br0.${toString vlan.vlanId}" {
            netdevConfig = {
              Kind = "vlan";
              Name = "br0.${toString vlan.vlanId}";
            };
            vlanConfig.Id = vlan.vlanId;
          }
        )
        addresses.vlans;
      networks = lib.mapAttrs'
        (name: vlan:
          lib.nameValuePair "03-br0.${toString vlan.vlanId}" {
            matchConfig.Name = "br0.${toString vlan.vlanId}";
            networkConfig = {
              LinkLocalAddressing = "no";
              DHCP = "no";
            };
            linkConfig.RequiredForOnline = "carrier";
          }
        )
        addresses.vlans;
    }

    # Host MacVLANs
    (lib.ext.mkMacvlanSetup {
      hostName = machine.hostName;
      interfaceName = "lan0";
      netdevPriority = 10;
      networkPriority = 20;
      mainTableMetric = 100;
      policyTableId = 200;
      policyPriority = 100;
      requiredForOnline = "routable";
    })
  ];

  # Boot kernel networking settings (related to ARP flux for macvlan)
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.arp_ignore" = 1; # Only respond if target IP is local address on receiving interface
    "net.ipv4.conf.all.arp_announce" = 2; # Use best local address for ARP requests
    "net.ipv4.conf.default.arp_ignore" = 1;
    "net.ipv4.conf.default.arp_announce" = 2;
  };
}
