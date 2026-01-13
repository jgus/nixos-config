with builtins;
{ lib, myLib }:
let
  # === Configuration ===
  network = rec {
    prefix = "172.22.";
    prefixLength = 16;
    defaultGateway = prefix + "0.1";
    prefix6 = "2001:55d:b00b:1::";
    prefix6Length = 64;
    domain = "home.gustafson.me";
    serviceMacPrefix = "00:24:0b:16:";
    dnsServers = [ "pihole-1" "pihole-2" "pihole-3" ];
  };
  group = {
    network = 0;
    servers = 1;
    home-automation = 2;
    services = 3;
    vms = 4;
    admin = 5;
    office = 31;
    study = 33;
  };
  records-conf =
    mapAttrs (k: v: { g = group.network; } // v)
      {
        router = { id = 1; mac = "d2:21:f9:d9:78:8c"; aliases = [ "gateway" ]; };
        switch-1g-poe = { id = 2; mac = "68:d7:9a:23:f1:70"; };
        switch-2g-poe = { id = 3; mac = "e4:38:83:e8:f3:b1"; };
        switch-10g = { id = 4; mac = "d8:b3:70:2b:3f:2f"; };
        ap-balcony = { id = 10; mac = "ac:8b:a9:69:2a:ea"; };
        ap-basement-hall = { id = 11; mac = "ac:8b:a9:69:36:b1"; };
        ap-bedroom = { id = 12; mac = "ac:8b:a9:69:3c:bf"; };
        ap-master-closet = { id = 13; mac = "ac:8b:a9:69:2d:01"; };
        ap-media = { id = 14; mac = "ac:8b:a9:69:33:f0"; };
        ap-mudroom = { id = 15; mac = "ac:8b:a9:69:3b:fc"; };
        ap-office = { id = 16; mac = "ac:8b:a9:69:31:52"; };
        ap-server = { id = 17; mac = "24:5a:4c:5e:bc:f6"; };
        switch-admin = { id = 20; mac = "80:2a:a8:9c:79:53"; };
        switch-extra = { id = 21; mac = "f4:e2:c6:59:a1:7d"; };
        switch-heater = { id = 22; mac = "f4:e2:c6:59:9e:37"; };
        switch-office = { id = 23; mac = "f4:e2:c6:59:9c:76"; };
        switch-study = { id = 24; mac = "f4:e2:c6:59:9c:4d"; };
        switch-gr = { id = 25; mac = "1c:6a:1b:9c:04:45"; };
        switch-c = { id = 30; mac = "f8:c2:88:23:8c:10"; };
        switch-d = { id = 31; mac = "ec:f4:bb:fe:71:f8"; };
        pi-be4492 = { id = 101; mac = "dc:a6:32:be:44:92"; aliases = [ "n-kvm" ]; };
      } //
    mapAttrs (k: v: { g = group.servers; } // v) {
      b1 = { id = 1; };
      c1-1 = { id = 2; };
      c1-2 = { id = 3; };
      d1 = { id = 4; };
      pi-67cba1 = { id = 65; aliases = [ "theater-pi" "theater-cec" ]; };
    } //
    mapAttrs (k: v: { g = group.home-automation; } // v) {
      sensor-hub-1 = { id = 2; mac = "70:b8:f6:9b:f3:83"; };
      zigbee-radio = { id = 6; mac = "ec:c9:ff:bc:7c:ef"; };
      zwave-radio-main = { id = 7; mac = "b0:b2:1c:93:62:4f"; };
      zwave-radio-upstairs = { id = 8; mac = "a0:b7:65:fa:bf:03"; };
      zwave-radio-basement = { id = 9; mac = "a0:b7:65:fa:be:97"; };
      zwave-radio-north = { id = 10; mac = "f8:b3:b7:c4:aa:d7"; };
      # smartwings-n = { id = 15; mac = "64:b7:08:17:38:53"; };
      # smartwings-s = { id = 16; mac = "08:3a:8d:b2:be:e3"; };
      somfy = { id = 17; mac = "00:0e:c6:aa:0a:86"; };
    } //
    mapAttrs (k: v: { g = group.services; } // v) {
      # Network
      pihole-1 = { id = 1; host = "b1"; aliases = [ "dhcp-1" "dns-1" "pihole" "dhcp" "dns" ]; };
      ntp = { id = 2; host = "b1"; };
      pihole-2 = { id = 4; host = "c1-1"; aliases = [ "dhcp-2" "dns-2" ]; };
      pihole-3 = { id = 5; host = "d1"; aliases = [ "dhcp-3" "dns-3" ]; };
      cloudflared = { id = 6; host = "c1-2"; };
      echo = { id = 7; host = "d1"; };

      # Storage
      samba = { id = 10; host = "c1-1"; aliases = [ "smb" "nas" ]; };
      samba-c1-2 = { id = 11; host = "c1-2"; };
      garage = { id = 12; host = "d1"; };
      owncloud = { id = 13; host = "c1-1"; aliases = [ "drive" ]; };
      owncloud-db = { id = 14; host = "c1-1"; };
      owncloud-redis = { id = 15; host = "c1-1"; };
      onlyoffice = { id = 16; host = "c1-2"; aliases = [ "office" ]; };

      # Web
      web = { id = 20; host = "c1-2"; };
      journal = { id = 21; host = "c1-2"; };
      journal-db = { id = 22; host = "c1-2"; };
      joyfulsong = { id = 23; host = "c1-2"; };
      joyfulsong-db = { id = 24; host = "c1-2"; };
      searxng = { id = 28; host = "c1-2"; };
      searxng-mcp = { id = 29; host = "c1-2"; };

      # Home Automation
      home-assistant = { id = 30; host = "b1"; aliases = [ "homeassistant" "ha" ]; };
      esphome = { id = 31; host = "c1-2"; };
      mosquitto = { id = 32; host = "b1"; aliases = [ "mqtt" ]; };
      zigbee2mqtt = { id = 33; host = "b1"; aliases = [ "z2m" ]; };
      ipmi-server = { id = 34; host = "b1"; };
      node-red = { id = 35; host = "b1"; };
      zwave-main = { id = 40; host = "b1"; };
      zwave-upstairs = { id = 41; host = "b1"; };
      zwave-basement = { id = 42; host = "b1"; };
      zwave-north = { id = 43; host = "b1"; };
      frigate = { id = 50; host = "d1"; };

      # Media
      plex = { id = 60; host = "d1"; };
      jellyfin = { id = 61; host = "d1"; };
      komga = { id = 62; host = "c1-2"; };
      lazylibrarian = { id = 63; host = "c1-2"; };
      calibre = { id = 64; host = "c1-2"; };
      audiobookshelf = { id = 65; host = "c1-2"; };

      # Download
      sabnzbd = { id = 70; host = "c1-2"; };
      qbittorrent = { id = 71; host = "c1-2"; };
      prowlarr = { id = 72; host = "c1-2"; };
      sonarr = { id = 73; host = "c1-2"; };
      radarr = { id = 74; host = "c1-2"; };
      lidarr = { id = 75; host = "c1-2"; };
      kapowarr = { id = 76; host = "c1-2"; };
      flaresolverr = { id = 77; host = "c1-2"; };

      # AI
      large-model-proxy = { id = 80; host = "d1"; aliases = [ "comfyui" ]; };
      ollama = { id = 81; host = "d1"; };
      qdrant = { id = 82; host = "d1"; };
      open-webui = { id = 88; host = "d1"; };
      sillytavern = { id = 89; host = "d1"; };

      # Other
      minecraft = { id = 100; host = "c1-2"; };
    } //
    mapAttrs (k: v: { g = group.admin; } // v) {
      c1-imc-1 = { id = 2; mac = "70:0f:6a:3b:46:01"; aliases = [ "c1-imc" ]; };
      c1-imc-2 = { id = 3; mac = "70:79:b3:09:49:16"; };
      c1-bmc-1 = { id = 12; mac = "b4:de:31:bd:a8:be"; };
      c1-bmc-2 = { id = 13; mac = "00:be:75:e0:a2:3e"; };
      d1-bmc = { id = 4; mac = "18:66:da:b6:45:d8"; };
      d2-bmc = { id = 100; mac = "84:2b:2b:57:53:84"; };
      d3-bmc = { id = 101; mac = "00:26:b9:49:cb:ff"; };
      josh-pc-bmc = { id = 5; mac = "18:31:bf:cf:20:0b"; };
      server-ups = { id = 6; mac = "28:29:86:7f:bf:21"; };
    } //
    mapAttrs (k: v: { g = group.office; } // v) {
      josh-pc = { id = 1; mac = "3c:fd:fe:e1:b9:d6"; };
      snap-mac = { id = 6; mac = "a4:fc:14:0d:f0:ea"; };
      snap-laptop = { id = 20; mac = "08:92:04:6e:38:61"; };
    } //
    mapAttrs (k: v: { g = group.study; } // v) {
      printer = { id = 2; mac = "f4:81:39:e4:0a:83"; };
      kitchen-lappy = { id = 3; mac = "74:e5:f9:e4:3f:59"; };
      melissa-lappy-eth = { id = 10; mac = "b4:45:06:82:81:47"; };
      melissa-lappy = { id = 11; mac = "f0:d4:15:30:c4:a6"; };
      john-lappy-eth = { id = 30; mac = "b4:45:06:82:81:46"; };
      john-lappy = { id = 31; mac = "f4:c8:8a:e8:8e:83"; };
      william-lappy-eth = { id = 40; mac = "b4:45:06:82:7e:db"; };
      william-lappy = { id = 41; mac = "f4:c8:8a:e8:e0:e0"; };
      lyra-lappy-eth = { id = 50; mac = "b4:45:06:82:7f:3d"; };
      lyra-lappy = { id = 51; mac = "f0:d4:15:30:c3:75"; };
      eden-lappy-eth = { id = 60; mac = "b4:45:06:82:82:e4"; };
      eden-lappy = { id = 61; mac = "f0:d4:15:30:c5:5a"; };
      hope-lappy-eth = { id = 70; mac = "b4:45:06:82:7e:e7"; };
      hope-lappy = { id = 71; mac = "f0:d4:15:30:c5:00"; };
      peter-lappy-eth = { id = 80; mac = "b4:45:06:82:7e:ff"; };
    } // {
      gr-tv = { g = 50; id = 2; mac = "64:e4:a5:61:30:0b"; };
      lr-shield = { g = 50; id = 3; mac = "00:04:4b:af:f0:0c"; };
      game-room-tv = { g = 56; id = 1; mac = "a0:6a:44:0f:bd:83"; };
      theater-projector = { g = 59; id = 1; mac = "e0:da:dc:17:ec:ef"; };
      theater-preamp = { g = 59; id = 2; mac = "00:1b:7c:0b:21:fb"; };
      theater-shield = { g = 59; id = 3; mac = "3c:6d:66:08:af:01"; };
      theater-bluray = { g = 59; id = 5; mac = "34:31:7f:dd:db:9b"; };
      theater-uc-dock = { g = 59; id = 9; mac = "28:37:2f:0c:25:df"; };
      camera-garage-s = { g = 100; id = 16; mac = "9c:8e:cd:3d:72:89"; };
      camera-garage-n = { g = 100; id = 17; mac = "9c:8e:cd:3d:7c:0b"; };
      camera-back-yard = { g = 110; id = 16; mac = "9c:8e:cd:3d:72:a6"; };
      camera-driveway = { g = 113; id = 16; mac = "9c:8e:cd:3d:88:2c"; };
      camera-n-side = { g = 115; id = 16; mac = "9c:8e:cd:3d:7c:1a"; };
      camera-patio = { g = 116; id = 16; mac = "fc:5f:49:39:1d:18"; };
      camera-pool = { g = 117; id = 16; mac = "9c:8e:cd:3d:73:2f"; };
      camera-porch-s = { g = 118; id = 16; mac = "9c:8e:cd:3d:73:12"; };
      camera-porch-n = { g = 118; id = 17; mac = "9c:8e:cd:3d:72:f6"; };
      camera-garage-rear = { g = 119; id = 16; mac = "9c:8e:cd:3d:72:9c"; };
      camera-s-side = { g = 119; id = 17; mac = "9c:8e:cd:3d:72:c0"; };
      camera-guest-patio = { g = 120; id = 16; mac = "9c:8e:cd:3d:88:7d"; };
    };
  iot = {
    server-climate = { ip = "172.21.1.20"; };
    sprinklers = { ip = "172.21.2.30"; };
    octoprint = { ip = "172.21.31.8"; };
    workshop-climate = { ip = "172.21.32.20"; };
    kitchen-cooktop = { ip = "172.21.40.2"; };
    ge-unknown-1 = { ip = "172.21.40.3"; };
    ge-unknown-2 = { ip = "172.21.40.4"; };
    ge-unknown-3 = { ip = "172.21.40.5"; };
    ice-maker = { ip = "172.21.40.6"; };
    frodo = { ip = "172.21.40.11"; };
    sam = { ip = "172.21.40.12"; };
    merry = { ip = "172.21.40.13"; };
    pippin = { ip = "172.21.40.14"; };
    theater-remote = { ip = "172.21.59.7"; };
    theater-uc-remote = { ip = "172.21.59.8"; };
    theater-climate = { ip = "172.21.59.20"; };
    ratgdo-1 = { ip = "172.21.100.11"; };
    ratgdo-2 = { ip = "172.21.100.12"; };
    ratgdo-3 = { ip = "172.21.100.13"; };
    ratgdo-4 = { ip = "172.21.100.14"; };
    balcony-fan = { ip = "172.21.111.11"; };
    doorbell-front = { ip = "172.21.118.2"; };
    doorbell-basement = { ip = "172.21.120.2"; };
  };

  # === Helper Functions ===
  toHex2 = x: lib.strings.fixedWidthString 2 "0" (lib.strings.toLower (lib.trivial.toHexString x));

  nameAndFqdn = name: [ name "${name}.${network.domain}" ];

  # === Complete Records ===
  # Set default ip, mac, and ip6 addresses; add IoT records
  records = (mapAttrs
    (k: v:
      rec {
        ip = "${network.prefix}${toString v.g}.${toString v.id}";
        mac = "${network.serviceMacPrefix}${toHex2 v.g}:${toHex2 v.id}";
        ip6 = myLib.macToIp6 network.prefix6 mac;
      } // v
    )
    records-conf) // iot;

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

  # === Name <-> IP Mappings ===
  nameToIp = buildAliasToAttr "ip";
  nameToIp6 = buildAliasToAttr "ip6";

  # All names with an associated ip address
  names = attrNames nameToIp;

  # All names with an associated ip6 address (everything but IoT)
  names6 = attrNames nameToIp6;

  # IP (4 or 6) -> list of names
  ipToNames = (lib.lists.groupBy (n: getAttr n nameToIp) names) // (lib.lists.groupBy (n: getAttr n nameToIp6) names6);

  # IP (4 or 6) -> list of names, includinh FQDNs, suitable for /etc/hosts generation
  hosts = mapAttrs (key: value: lib.lists.flatten (map nameAndFqdn value)) ipToNames;

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
    "--network=macvlan"
    "--mac-address=${records.${service}.mac}"
    "--hostname=${service}"
    "--ip=${records.${service}.ip}"
    "--ip6=${records.${service}.ip6}"
    "--dns-search=${network.domain}"
  ] ++ map (name: "--dns=${records.${name}.ip}") network.dnsServers;

  # Exhaustive host records, for DNS containers
  containerAddAllHosts = lib.lists.flatten [
    (map (n: map (name: "--add-host=${name}:${getAttr n nameToIp}") (nameAndFqdn n)) names)
    (map (n: map (name: "--add-host=${name}:${getAttr n nameToIp6}") (nameAndFqdn n)) names6)
  ];
in
{
  inherit
    network
    group
    records
    nameToIp
    nameToIp6
    serverNames
    hosts
    dhcpReservations
    containerOptions
    containerAddAllHosts;
}
