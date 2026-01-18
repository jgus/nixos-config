with builtins;
{ addresses, lib, machine, pkgs, ... }:
let
  # === Helper Functions ===
  nameAndFqdn = name: [ name "${name}.${addresses.network.domain}" ];

  # Convert MAC address to EUI-64 IPv6 interface identifier
  # Takes a net6 argument like "2001:55d:b00b:1::/64"
  macToIp6 = net6: mac:
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
    in
    lib.net.cidr.host "::${suffix}" net6;

  # === Complete Records ===
  # Set default ip, mac, and ip6 addresses; add IoT records
  records = (mapAttrs
    (k: v:
      rec {
        ip = lib.net.cidr.host (v.g * 256 + v.id) addresses.network.net4;
        mac = lib.net.mac.add (v.g * 256 + v.id) addresses.network.serviceMacBase;
        ip6 = macToIp6 addresses.network.net6 mac;
      } // v
    )
    addresses.records-conf) // addresses.iot;

  # === Alias Resolution ===
  # Lists of records that have a host attribute (ie hosted services)
  hostedNames = filter (n: (getAttr n records) ? host) (attrNames records);

  # Map alias -> canonical name, for auto-generated host aliases (e.g. pihole-1-host -> b1)
  hostAliasList = map
    (n:
      {
        name = "${n}-host";
        value = records.${n}.host;
      }
    )
    hostedNames;

  # Map alias -> canonical name, for explicitly assigned aliases
  assignedAliasList = lib.lists.flatten (map
    (n: map (a: { name = a; value = n; }) (records.${n}.aliases or [ ]))
    (attrNames records)
  );

  # Map alias -> canonical name
  aliases = listToAttrs (assignedAliasList ++ hostAliasList);

  # === Name -> Attribute Mapping ===
  # Map canonical name -> attribute (given by attrName)
  # Only includes items where the attribute exists on the given record
  buildNameToAttr = attrName:
    listToAttrs (lib.lists.flatten (map
      (k:
        let r = records.${k}; in
        lib.optional (hasAttr attrName r) [{ name = k; value = r.${attrName}; }]
      )
      (attrNames records)));

  # buildNameToAttr, with aliases too
  buildAliasToAttr = attrName:
    let
      nameToAttr = buildNameToAttr attrName;
    in
    nameToAttr // (mapAttrs (k: v: getAttr v nameToAttr) aliases);
in
{
  ext = rec {
    # === Name <-> IP Mappings ===
    nameToMac = buildAliasToAttr "mac";
    nameToIp = buildAliasToAttr "ip";
    nameToIp6 = buildAliasToAttr "ip6";
    nameToHost = buildAliasToAttr "host";
    nameToIdMajor = buildAliasToAttr "g";
    nameToIdMinor = buildAliasToAttr "id";

    # Formats the given nix expression as JSON, Toml, YAML, or XML. Returns a file path.
    prettyJson = x: ((pkgs.formats.json { }).generate "json" x);
    prettyToml = x: ((pkgs.formats.toml { }).generate "toml" x);
    prettyYaml = x: ((pkgs.formats.yaml { }).generate "yaml" x);
    prettyXml = x: ((pkgs.formats.xml { }).generate "xml" x);

    # Convert values to string for debugging in test assertions
    toDebugStr = x:
      if isList x || isAttrs x then toJSON x
      else toString x;

    # === Addresses Library Functions ===

    # IP (4 or 6) -> list of names, including FQDNs, suitable for /etc/hosts generation
    hosts =
      let
        # IP (4 or 6) -> list of names
        ipToNames = (lib.lists.groupBy (n: getAttr n nameToIp) (attrNames nameToIp)) // (lib.lists.groupBy (n: getAttr n nameToIp6) (attrNames nameToIp6));
      in
      mapAttrs (key: value: lib.lists.flatten (map nameAndFqdn value)) ipToNames;

    # Names of physical servers
    serverNames = filter (n: (hasAttr n records) && (records."${n}" ? g) && (records."${n}".g == 1)) (attrNames records);

    # List of name/ip/mac records, suitable for generating a dhcp reservation list
    dhcpReservations = lib.lists.flatten (map
      (k:
        let
          r = (getAttr k records);
        in
        lib.optional (r ? mac) { name = k; ip = r.ip; mac = r.mac; }
      )
      (attrNames records)
    );

    # Network options to be added to every container service
    containerOptions = service: [
      "--network=hostlan"
      "--mac-address=${records.${service}.mac}"
      "--hostname=${service}"
      "--ip=${records.${service}.ip}"
      "--ip6=${records.${service}.ip6}"
      "--dns-search=${addresses.network.domain}"
    ] ++ map (name: "--dns=${records.${name}.ip}") addresses.network.dnsServers;

    # Exhaustive host records, for DNS containers
    containerAddAllHosts = lib.lists.flatten [
      (map (n: map (name: "--add-host=${name}:${getAttr n nameToIp}") (nameAndFqdn n)) (attrNames nameToIp))
      (map (n: map (name: "--add-host=${name}:${getAttr n nameToIp6}") (nameAndFqdn n)) (attrNames nameToIp6))
    ];

    # Create complete macvlan setup including netdev, parent attachment, and network config
    # This encapsulates the entire pattern used in both network.nix and services.nix
    mkMacvlanSetup =
      { hostName
      , interfaceName
      , netdevPriority
      , networkPriority
      , mainTableMetric
      , policyTableId
      , policyPriority
      , addPrefixRoute ? true
      , requiredForOnline ? "no"
      }:
      let
        # Generate route entries for both IPv4 and IPv6 prefixes
        mkRoutesForPrefix = { metric, table ? null }:
          let
            baseRoutes = [
              { Destination = "${addresses.network.net4}"; Metric = metric; }
              { Destination = "${addresses.network.net6}"; Metric = metric; }
            ];
          in
          if table == null then baseRoutes else
          map (r: r // { Table = table; }) baseRoutes;
      in
      {
        netdevs."${netdevPriority}-${interfaceName}" = {
          netdevConfig = {
            Kind = "macvlan";
            Name = interfaceName;
            MACAddress = nameToMac.${hostName};
          };
          macvlanConfig.Mode = "bridge";
        };

        networks."05-${machine.lan-interface}".macvlan = [ interfaceName ];

        networks."${networkPriority}-${interfaceName}" = {
          matchConfig.Name = interfaceName;
          networkConfig = {
            DHCP = "no";
            IPv6AcceptRA = "yes";
            LinkLocalAddressing = "ipv6";
          };
          addresses = [
            { Address = "${nameToIp.${hostName}}/${toString (lib.net.cidr.length addresses.network.net4)}"; AddPrefixRoute = addPrefixRoute; }
            { Address = "${nameToIp6.${hostName}}/${toString (lib.net.cidr.length addresses.network.net6)}"; AddPrefixRoute = addPrefixRoute; }
          ];
          gateway = [ addresses.network.defaultGateway ];
          routes = (mkRoutesForPrefix {
            # Main table routes
            metric = mainTableMetric;
          }) ++ (mkRoutesForPrefix {
            # Policy table routes
            metric = mainTableMetric;
            table = policyTableId;
          }) ++ [{
            # Default route
            Destination = "0.0.0.0/0";
            Gateway = addresses.network.defaultGateway;
            Table = policyTableId;
          }];
          routingPolicyRules = map
            (a: {
              From = a;
              Table = policyTableId;
              Priority = policyPriority;
            }) [ nameToIp.${hostName} nameToIp6.${hostName} ];
          linkConfig.RequiredForOnline = requiredForOnline;
        };
      };
  };
}
