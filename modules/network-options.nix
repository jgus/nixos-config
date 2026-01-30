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
                name = lib.mkOption {
                  description = "Short host name";
                  type = str;
                  default = name;
                };
                fqdn = lib.mkOption {
                  description = "Fully-qualified domain name";
                  type = str;
                  default = "${name}.${networkConfig.domain}";
                  readOnly = true;
                };
                g = lib.mkOption {
                  description = "Group ID override";
                  type = ints.u8;
                  default = groupConfig.id;
                };
                id = lib.mkOption {
                  description = "Host ID within group";
                  type = ints.u8;
                };
                ip4 = lib.mkOption {
                  description = "IPv4 address";
                  type = net.ipv4;
                  default = lib.net.cidr.host (config.g * 256 + config.id) networkConfig.net4;
                };
                mac = lib.mkOption {
                  description = "MAC address";
                  type = nullOr net.mac;
                  default =
                    if (groupConfig.assignMac && networkConfig.assignedMacBase != null)
                    then (lib.net.mac.add (config.g * 256 + config.id) networkConfig.assignedMacBase)
                    else null;
                };
                ip6 = lib.mkOption {
                  description = "IPv6 address";
                  type = nullOr net.ipv6;
                  default =
                    if (groupConfig.assignIp6 && networkConfig.net6 != null && config.mac != null)
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

  # # Temp test config
  # config =
  #   {
  #     assertions = [
  #       {
  #         assertion =
  #           let
  #             vlanIds = lib.attrValues (lib.mapAttrs (name: vlan: vlan.vlanId) config.homelab.network.vlans);
  #           in
  #           length vlanIds == length (lib.unique vlanIds);
  #         message = "Duplicate VLAN IDs detected in homelab.network.vlans";
  #       }
  #     ] ++ (lib.mapAttrsToList
  #       (name: vlan: {
  #         assertion = vlan.vlanId != null;
  #         message = "homelab.network.vlans.${name}.vlanId must be set";
  #       })
  #       config.homelab.network.vlans) ++ [
  #     ];
  #   };
}
