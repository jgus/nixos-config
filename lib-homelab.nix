with builtins;
{ addresses, lib, pkgs, ... }:
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
      let
        vlan = if v ? vlan then addresses.vlans.${v.vlan} else addresses.network;
        mac = lib.net.mac.add (v.g * 256 + v.id) addresses.network.assignedMacBase;
      in
      {
        ip = lib.net.cidr.host (v.g * 256 + v.id) vlan.net4;
        inherit mac;
      } // lib.optionalAttrs (vlan ? net6) { ip6 = macToIp6 vlan.net6 mac; } // v
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
  homelab = rec {
    inherit macToIp6;

    # Merge multiple attribute sets recursively
    recursiveUpdates = listOfSets:
      lib.fold (attrs: acc: lib.recursiveUpdate attrs acc) { } listOfSets;

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
    containerOptions = service:
      let
        record = records.${service};
        vlan = if record ? vlan then addresses.vlans.${record.vlan} else addresses.network;
        suffix = if vlan ? vlanId then ".${toString vlan.vlanId}" else "";
      in
      [
        "--network=hostlan${suffix}"
        "--mac-address=${record.mac}"
        "--hostname=${service}"
        "--ip=${record.ip}"
        "--dns-search=${addresses.network.domain}"
      ]
      ++ map (name: "--dns=${records.${name}.ip}") addresses.network.dnsServers
      ++ lib.optional (record ? ip6) "--ip6=${record.ip6}"
      ++ (if (record ? ip6) then (map (name: "--dns=${records.${name}.ip6}") addresses.network.dnsServers) else [ ]);

    # Exhaustive host records, for DNS containers
    containerAddAllHosts = lib.lists.flatten [
      (map (n: map (name: "--add-host=${name}:${getAttr n nameToIp}") (nameAndFqdn n)) (attrNames nameToIp))
      (map (n: map (name: "--add-host=${name}:${getAttr n nameToIp6}") (nameAndFqdn n)) (attrNames nameToIp6))
    ];

    macvlanInterfaceName = serviceName: "mv${toString nameToIdMajor.${serviceName}}x${toString nameToIdMinor.${serviceName}}";

    # Create complete macvlan setup including netdev, parent attachment, and network config
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
        vlan = if records.${hostName} ? vlan then addresses.vlans.${records.${hostName}.vlan} else addresses.network;
      in
      {
        netdevs."${toString netdevPriority}-${interfaceName}" = {
          netdevConfig = {
            Kind = "macvlan";
            Name = interfaceName;
            MACAddress = nameToMac.${hostName};
          };
          macvlanConfig.Mode = "bridge";
        };

        networks."05-br0".macvlan = [ interfaceName ];

        networks."${toString networkPriority}-${interfaceName}" = {
          matchConfig.Name = interfaceName;
          networkConfig = {
            DHCP = "no";
            IPv6AcceptRA = "yes";
            LinkLocalAddressing = "ipv6";
          };
          addresses = [{
            Address = "${nameToIp.${hostName}}/${toString (lib.net.cidr.length vlan.net4)}";
            AddPrefixRoute = addPrefixRoute;
          }] ++ lib.optional (vlan ? net6) {
            Address = "${nameToIp6.${hostName}}/${toString (lib.net.cidr.length vlan.net6)}";
            AddPrefixRoute = addPrefixRoute;
          };
          gateway = [ addresses.network.defaultGateway ];
          routes = [
            # Default route
            {
              Destination = "0.0.0.0/0";
              Gateway = addresses.network.defaultGateway;
              Table = policyTableId;
            }
            # Main table routes
            { Destination = "${vlan.net4}"; Metric = mainTableMetric; }

            # Policy table routes
            { Destination = "${vlan.net4}"; Metric = mainTableMetric; Table = policyTableId; }
          ]
          ++ lib.optional (vlan ? net6) { Destination = "${vlan.net6}"; Metric = mainTableMetric; }
          ++ lib.optional (vlan ? net6) { Destination = "${vlan.net6}"; Metric = mainTableMetric; Table = policyTableId; };
          routingPolicyRules = map
            (a: {
              From = a;
              Table = policyTableId;
              Priority = policyPriority;
            }) [ nameToIp.${hostName} nameToIp6.${hostName} ];
          linkConfig.RequiredForOnline = requiredForOnline;
        };
      };

    # === Name -> Attribute Mapping ===
    storagePath = serviceName: "/service/${serviceName}";
    storageBackupPath = serviceName: "/storage/service/${serviceName}";

    # This is a version of pkgs.dockerTools.pullImage
    # https://github.com/NixOS/nixpkgs/blob/d33f940b617cb63dc0652b174d11517046c664c6/pkgs/build-support/docker/default.nix#L141
    # This adds REGISTRY_AUTH_FILE to bypass a Skopeo bug where it uses getpid() instead of getuid() when XDG_RUNTIME_DIR is unset, causing /run/containers/<PID>/auth.json permission errors.
    pullImage =
      let
        fixName = name: replaceStrings [ "/" ":" ] [ "-" "-" ] name;
        defaultArchitecture = pkgs.go.GOARCH;
      in
      lib.fetchers.withNormalizedHash { } (
        { imageName
        , # To find the digest of an image, you can use skopeo:
          # see doc/functions.xml
          imageDigest
        , outputHash
        , outputHashAlgo
        , os ? "linux"
        , # Image architecture, defaults to the architecture of the `hostPlatform` when unset
          arch ? defaultArchitecture
        , # This is used to set name to the pulled image
          finalImageName ? imageName
        , # This used to set a tag to the pulled image
          finalImageTag ? "latest"
        , # This is used to disable TLS certificate verification, allowing access to http registries on (hopefully) trusted networks
          tlsVerify ? true
        , name ? fixName "docker-image-${finalImageName}-${finalImageTag}.tar"
        ,
        }:

        pkgs.runCommand name
          {
            inherit imageDigest;
            imageName = finalImageName;
            imageTag = finalImageTag;
            impureEnvVars = lib.fetchers.proxyImpureEnvVars;

            inherit outputHash outputHashAlgo;
            outputHashMode = "flat";

            nativeBuildInputs = [ pkgs.skopeo ];
            SSL_CERT_FILE = "${pkgs.cacert.out}/etc/ssl/certs/ca-bundle.crt";
            REGISTRY_AUTH_FILE = "$TMPDIR/auth.json";

            sourceURL = "docker://${imageName}@${imageDigest}";
            destNameTag = "${finalImageName}:${finalImageTag}";
          }
          ''
            skopeo \
              --insecure-policy \
              --tmpdir=$TMPDIR \
              --override-os ${os} \
              --override-arch ${arch} \
              copy \
              --src-tls-verify=${lib.boolToString tlsVerify} \
              "$sourceURL" "docker-archive://$out:$destNameTag" \
              | cat  # pipe through cat to force-disable progress bar
          ''
      );
  };
}
