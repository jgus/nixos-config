{ config, lib, ... }:
with builtins;
with lib.types;
let
  mkHostGroupOption = networkConfig: lib.mkOption {
    description = "Host groups";
    type = attrsOf (submodule ({ name, config, ... }:
      let
        # groupName = name;
        groupConfig = config;
      in
      {
        options = {
          id = lib.mkOption {
            description = "Group ID";
            type = ints.u8;
          };
          assignMac = lib.mkOption {
            description = "Whether to assign MAC addresses for hosts in this group";
            type = bool;
            default = false;
          };
          assignIp6 = lib.mkOption {
            description = "Whether to assign IPv6 addresses for hosts in this group";
            type = bool;
            default = false;
          };
          hosts = lib.mkOption {
            description = "Host definitions";
            type = attrsOf (submodule ({ name, config, ... }: {
              options = {
                id = lib.mkOption {
                  description = "Host ID within group";
                  type = ints.u8;
                };
                ip4 = lib.mkOption {
                  description = "IPv4 address";
                  type = net.ipv4;
                  default = lib.net.cidr.host (groupConfig.id * 256 + config.id) networkConfig.net4;
                };
                mac = lib.mkOption {
                  description = "MAC address";
                  type = nullOr net.mac;
                  default =
                    if (groupConfig.assignMac && networkConfig.assignedMacBase != null)
                    then (lib.net.mac.add (groupConfig.id * 256 + config.id) networkConfig.assignedMacBase)
                    else null;
                };
                ip6 = lib.mkOption {
                  description = "IPv6 address";
                  type = nullOr net.ipv6;
                  default =
                    if (networkConfig.net6 != null && config.mac != null)
                    then (lib.homelab.macToIp6 networkConfig.net6 config.mac)
                    else null;
                };
                host = lib.mkOption {
                  description = "If this is a virtual service, this specifies its physical host";
                  type = nullOr str;
                  default = null;
                };
                alias = lib.mkOption {
                  description = "Alias target - this host name is an alias for the given host";
                  type = nullOr str;
                  default = null;
                };
              };
            }));
          };
        };
      }));
  };
in
{
  options.homelab = {
    network = lib.mkOption
      {
        description = "Network configuration";
        type = submodule ({ name, config, ... }:
          let
            networkConfig = config;
          in
          {
            options = {
              net4 = lib.mkOption {
                description = "IPv4 network for LAN";
                type = net.cidrv4;
              };
              defaultGateway = lib.mkOption {
                description = "IPv4 default gateway";
                type = net.ipv4;
                default = lib.net.cidr.host 1 config.net4;
              };
              net6 = lib.mkOption {
                description = "IPv6 network for LAN";
                type = net.cidrv6;
              };
              local6 = lib.mkOption {
                description = "IPv6 network for local site";
                type = net.cidrv6;
              };
              domain = lib.mkOption {
                description = "Local domain name";
                type = str;
              };
              assignedMacBase = lib.mkOption {
                description = "Base MAC address for assigned MACs";
                type = net.mac;
              };
              dnsServers = lib.mkOption {
                description = "DNS server hostnames";
                type = listOf str;
              };
              publicDomain = lib.mkOption {
                description = "Public domain name";
                type = str;
              };
              hosts = mkHostGroupOption config;
              vlans = lib.mkOption {
                description = "VLAN definitions";
                type = attrsOf (submodule ({ name, config, ... }: {
                  options = {
                    vlanId = lib.mkOption {
                      description = "VLAN ID";
                      type = addCheck ints.unsigned (x: 0 < x && x <= 4096);
                    };
                    net4 = lib.mkOption {
                      description = "IPv4 network";
                      type = net.cidrv4;
                    };
                    defaultGateway = lib.mkOption {
                      description = "IPv4 default gateway";
                      type = net.ipv4;
                      default = lib.net.cidr.host 1 config.net4;
                    };
                    net6 = lib.mkOption {
                      description = "IPv6 network";
                      type = nullOr net.cidrv6;
                      default = null;
                    };
                    hosts = mkHostGroupOption (config // { inherit (networkConfig) assignedMacBase; });
                  };
                }));
              };
            };
          });
      };
  };

  # Temp test config
  config =
    let
      # Enable fake config for testing
      enableTestConfig = false;
    in
    {
      # Fake config for testing
      homelab.network = lib.mkIf enableTestConfig {
        net4 = "172.16.0.0/16";
        net6 = "1:2:3:1::/64";
        local6 = "1:2:3::/48";
        assignedMacBase = "12:34:56:00:00:00";
        hosts = {
          infrastructure = {
            id = 0;
            hosts = {
              router = { id = 1; };
            };
          };
          services = {
            id = 5;
            assignMac = true;
            assignIp6 = true;
            hosts = {
              echo = { id = 17; };
            };
          };
        };
        vlans = {
          foo = {
            vlanId = 2;
            net4 = "172.17.0.0/16";
          };
          bar = {
            vlanId = 3;
            net4 = "172.18.0.0/16";
            net6 = "1:2:3:3::/64";
            hosts = {
              services = {
                id = 5;
                assignMac = true;
                assignIp6 = true;
                hosts = {
                  peer = { id = 21; };
                };
              };
            };
          };
        };
      };

      assertions = [
        # Full-time assertions
        {
          assertion =
            let
              vlanIds = lib.attrValues (lib.mapAttrs (name: vlan: vlan.vlanId) config.homelab.network.vlans);
            in
            length vlanIds == length (lib.unique vlanIds);
          message = "Duplicate VLAN IDs detected in homelab.network.vlans";
        }
      ] ++ (lib.mapAttrsToList
        (name: vlan: {
          assertion = vlan.vlanId != null;
          message = "homelab.network.vlans.${name}.vlanId must be set";
        })
        config.homelab.network.vlans) ++ [
      ] ++ (if enableTestConfig then [
        # Assertions on test config
        {
          assertion = config.homelab.network.defaultGateway == "172.16.0.1";
          message = "network.defaultGateway";
        }
        {
          assertion = config.homelab.network.hosts.infrastructure.hosts.router.ip4 == "172.16.0.1";
          message = "network.hosts.infrastructure.hosts.router.ip4";
        }
        {
          assertion = config.homelab.network.hosts.services.hosts.echo.ip4 == "172.16.5.17";
          message = "network.hosts.services.hosts.echo.ip4";
        }
        {
          assertion = config.homelab.network.hosts.services.hosts.echo.mac == "12:34:56:00:05:11";
          message = "network.hosts.services.hosts.echo.mac";
        }
        {
          assertion = config.homelab.network.hosts.services.hosts.echo.ip6 == "1:2:3:1:1034:56ff:fe00:511";
          message = "network.hosts.services.hosts.echo.ip6";
        }
        {
          assertion = config.homelab.network.vlans.bar.hosts.services.hosts.peer.ip4 == "172.18.5.21";
          message = "network.vlans.bar.hosts.services.hosts.peer.ip4";
        }
        {
          assertion = config.homelab.network.vlans.bar.hosts.services.hosts.peer.mac == "12:34:56:00:05:15";
          message = "network.vlans.bar.hosts.services.hosts.peer.mac";
        }
        {
          assertion = config.homelab.network.vlans.bar.hosts.services.hosts.peer.ip6 == "1:2:3:3:1034:56ff:fe00:515";
          message = "network.vlans.bar.hosts.services.hosts.peer.ip6";
        }
        {
          assertion = config.homelab.network.vlans.foo.defaultGateway == "172.17.0.1";
          message = "network.vlans.foo.defaultGateway";
        }
      ] else [ ]);
    };
}
