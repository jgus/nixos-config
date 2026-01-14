with builtins;
{ lib, pkgs, ... }:
{
  # Create complete macvlan setup including netdev, parent attachment, and network config
  # This encapsulates the entire pattern used in both network.nix and services.nix
  mkMacvlanSetup =
    { interfaceName
    , mac
    , ipv4Address
    , ipv6Address
    , parentInterface
    , netdevPriority
    , networkPriority
    , ipv4Prefix
    , ipv4PrefixLength
    , ipv6Prefix
    , ipv6PrefixLength
    , defaultGateway
    , mainTableMetric
    , policyTableId
    , policyPriority
    , addPrefixRoute ? true
    , requiredForOnline ? "no"
    }:
    let
      # Generate route entries for both IPv4 and IPv6 prefixes
      mkRoutesForPrefix = { ipv4Prefix, ipv4PrefixLength, ipv6Prefix, ipv6PrefixLength, metric, table ? null }:
        let
          baseRoutes = [
            { Destination = "${ipv4Prefix}0.0/${toString ipv4PrefixLength}"; Metric = metric; }
            { Destination = "${ipv6Prefix}/${toString ipv6PrefixLength}"; Metric = metric; }
          ];
        in
        if table == null then baseRoutes else
        map (r: r // { Table = table; }) baseRoutes;

      mainTableRoutes = mkRoutesForPrefix {
        inherit ipv4Prefix ipv4PrefixLength ipv6Prefix ipv6PrefixLength;
        metric = mainTableMetric;
      };
      policyTableRoutes = mkRoutesForPrefix {
        inherit ipv4Prefix ipv4PrefixLength ipv6Prefix ipv6PrefixLength;
        metric = mainTableMetric;
        table = policyTableId;
      };
      defaultRoute = {
        Destination = "0.0.0.0/0";
        Gateway = defaultGateway;
        Table = policyTableId;
      };
      networkBase = {
        matchConfig.Name = interfaceName;
        networkConfig = {
          DHCP = "no";
          IPv6AcceptRA = "yes";
          LinkLocalAddressing = "ipv6";
        };
        addresses = [
          { Address = "${ipv4Address}/${toString ipv4PrefixLength}"; AddPrefixRoute = addPrefixRoute; }
          { Address = "${ipv6Address}/${toString ipv6PrefixLength}"; AddPrefixRoute = addPrefixRoute; }
        ];
        gateway = [ defaultGateway ];
        routes = mainTableRoutes ++ policyTableRoutes ++ [ defaultRoute ];
        routingPolicyRules = map
          (a: {
            From = a;
            Table = policyTableId;
            Priority = policyPriority;
          }) [ ipv4Address ipv6Address ];
        linkConfig.RequiredForOnline = requiredForOnline;
      };
    in
    {
      netdevs."${netdevPriority}-${interfaceName}" = {
        netdevConfig = {
          Kind = "macvlan";
          Name = interfaceName;
          MACAddress = mac;
        };
        macvlanConfig.Mode = "bridge";
      };

      networks."05-${parentInterface}".macvlan = [ interfaceName ];

      networks."${networkPriority}-${interfaceName}" = networkBase;
    };

  # Convert MAC address to EUI-64 IPv6 interface identifier
  # Takes a prefix argument like "2001:55d:b00b:1::"
  macToIp6 = prefix: mac:
    let
      octets = lib.splitString ":" mac;
      o = map lib.trivial.fromHexString octets;
      # Flip the Universal/Local bit (bit 1, i.e., XOR with 0x02) on first octet
      o0flipped = lib.trivial.bitXor (elemAt o 0) 2;
      eui64 = [ o0flipped (elemAt o 1) (elemAt o 2) 255 254 (elemAt o 3) (elemAt o 4) (elemAt o 5) ];
      toHex4 = a: b: lib.strings.toLower (lib.trivial.toHexString (a * 256 + b));
      suffix = lib.concatStringsSep ":" [
        (toHex4 (elemAt eui64 0) (elemAt eui64 1))
        (toHex4 (elemAt eui64 2) (elemAt eui64 3))
        (toHex4 (elemAt eui64 4) (elemAt eui64 5))
        (toHex4 (elemAt eui64 6) (elemAt eui64 7))
      ];
      prefixBase = lib.strings.removeSuffix "::" prefix;
    in
    "${prefixBase}:${suffix}";

  prettyJson = x: ((pkgs.formats.json { }).generate "json" x);
  prettyToml = x: ((pkgs.formats.toml { }).generate "toml" x);
  prettyYaml = x: ((pkgs.formats.yaml { }).generate "yaml" x);

  # Convert values to string for debugging in test assertions
  toDebugStr = x:
    if isString x then x
    else if isInt x || isBool x then toString x
    else if isList x then toJSON x
    else if isAttrs x then toJSON x
    else toString x;
}
