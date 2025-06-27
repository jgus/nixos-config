with builtins;
let
  pkgs = import <nixpkgs> { };
  lib = import <nixpkgs/lib>;
  network = rec {
    prefix = "172.22.";
    prefixLength = 16;
    defaultGateway = prefix + "0.1";
    prefix6 = "2001:55d:b00b:1::";
    prefix6Length = 64;
    domain = "home.gustafson.me";
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
        switch-gr = { id = 21; mac = "f4:e2:c6:59:a1:7d"; };
        switch-heater = { id = 22; mac = "f4:e2:c6:59:9e:37"; };
        switch-office = { id = 23; mac = "f4:e2:c6:59:9c:76"; };
        switch-study = { id = 24; mac = "f4:e2:c6:59:9c:4d"; };
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
      zigbee = { id = 6; mac = "ec:c9:ff:bc:7c:ef"; };
      zwave-radio-main = { id = 7; mac = "b0:b2:1c:93:62:4f"; };
      zwave-radio-upstairs = { id = 8; mac = "a0:b7:65:fa:bf:03"; };
      zwave-radio-basement = { id = 9; mac = "a0:b7:65:fa:be:97"; };
      # smartwings-n = { id = 15; mac = "64:b7:08:17:38:53"; };
      # smartwings-s = { id = 16; mac = "08:3a:8d:b2:be:e3"; };
      somfy = { id = 17; mac = "00:0e:c6:aa:0a:86"; };
    } //
    mapAttrs (k: v: { g = group.services; } // v) {
      pihole-1 = { id = 1; host = "b1"; aliases = [ "dhcp-1" "dns-1" "pihole" "dhcp" "dns" ]; };
      ntp = { id = 2; host = "b1"; };
      landing = { id = 3; host = "b1"; };
      pihole-2 = { id = 4; host = "c1-1"; aliases = [ "dhcp-2" "dns-2" ]; };
      pihole-3 = { id = 5; host = "d1"; aliases = [ "dhcp-3" "dns-3" ]; };
      samba = { id = 10; host = "c1-1"; aliases = [ "smb" "nas" ]; };
      syncthing = { id = 11; host = "c1-1"; };
      garage = { id = 12; host = "d1"; };
      web-swag = { id = 20; host = "c1-2"; };
      web-db = { id = 21; host = "c1-2"; aliases = [ "db" ]; };
      web-db-admin = { id = 22; host = "c1-2"; };
      owncloud = { id = 23; host = "c1-1"; aliases = [ "drive" ]; };
      owncloud-db = { id = 24; host = "c1-1"; };
      owncloud-redis = { id = 25; host = "c1-1"; };
      onlyoffice = { id = 26; host = "c1-2"; aliases = [ "office" ]; };
      home-assistant = { id = 30; host = "b1"; aliases = [ "homeassistant" "ha" ]; };
      esphome = { id = 31; host = "c1-2"; };
      mosquitto = { id = 32; host = "b1"; aliases = [ "mqtt" ]; };
      zigbee2mqtt = { id = 33; host = "b1"; aliases = [ "z2m" ]; };
      ipmi-server = { id = 34; host = "b1"; };
      node-red = { id = 35; host = "b1"; };
      zwave-main = { id = 40; host = "b1"; };
      zwave-upstairs = { id = 41; host = "b1"; };
      zwave-basement = { id = 42; host = "b1"; };
      frigate = { id = 50; host = "d1"; };
      plex = { id = 60; host = "d1"; };
      sabnzbd = { id = 70; host = "c1-2"; };
      transmission = { id = 71; host = "c1-2"; };
      prowlarr = { id = 72; host = "c1-2"; };
      sonarr = { id = 73; host = "c1-2"; };
      radarr = { id = 74; host = "c1-2"; };
      lidarr = { id = 75; host = "c1-2"; };
      mylar = { id = 76; host = "c1-2"; };
      komga = { id = 77; host = "c1-2"; };
      flaresolverr = { id = 78; host = "c1-2"; };
      minecraft = { id = 100; host = "c1-2"; };
      userbox-nathaniel = { id = 110; host = "c1-2"; };
    } //
    mapAttrs (k: v: { g = group.vms; } // v) {
      vm1 = { id = 1; host = "d1"; dns = "host"; };
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
      hope-lappy-eth = { id = 70; mac = "f4:c8:8a:e8:e1:a8"; };
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
  zeroPad = (s: n: if (stringLength s) >= n then s else (zeroPad ("0" + s) n));
  toHex2 = (x: zeroPad (lib.strings.toLower (lib.trivial.toHexString x)) 2);
  getIp = (name:
    let r = (getAttr name records-conf); in
    if (r ? dns) then (getIp (if (r.dns == "host") then r.host else r.dns)) else lib.concatStrings [ network.prefix (toString r.g) "." (toString r.id) ]
  );
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
    theater-climate = { ip = "172.21.59.20"; };
    ratgdo-1 = { ip = "172.21.100.11"; };
    ratgdo-2 = { ip = "172.21.100.12"; };
    ratgdo-3 = { ip = "172.21.100.13"; };
    ratgdo-4 = { ip = "172.21.100.14"; };
    balcony-fan = { ip = "172.21.111.11"; };
    doorbell-front = { ip = "172.21.118.2"; };
    doorbell-basement = { ip = "172.21.120.2"; };
  };
  macToIp6 = mac: readFile (derivation {
    name = "ipv6";
    builder = "/bin/sh";
    args = [ "-c" "${pkgs.ipv6calc}/bin/ipv6calc --in prefix+mac --out ipv6addr --action prefixmac2ipv6 ${network.prefix6}/${toString network.prefix6Length} ${mac} | ${pkgs.coreutils}/bin/tr -d '\n' | ${pkgs.gnused}/bin/sed 's|/.*||' >$out" ];
    system = builtins.currentSystem;
  });
  records = (mapAttrs
    (k: v:
      { ip = getIp k; }
        //
        (if (v ? dns) then { } else
        let
          mac = if (v ? mac) then v.mac else (lib.concatStrings [ "00:24:0b:16:" (toHex2 v.g) ":" (toHex2 v.id) ]);
          ip6 = macToIp6 mac;
        in
        { inherit mac ip6; }
        )
        //
        v
    )
    records-conf) // iot;
  hostedNames = filter (n: (getAttr n records) ? host) (attrNames records);
  assignedAliasList = lib.lists.flatten (map (n: let r = (getAttr n records); in (if (r ? aliases) then (map (a: { name = a; value = n; }) r.aliases) else [ ])) (attrNames records));
  hostAliasList = map (n: let r = (getAttr n records); in { name = "${n}-host"; value = r.host; }) hostedNames;
  aliases = listToAttrs (assignedAliasList ++ hostAliasList);
  realNameToIp = listToAttrs (lib.lists.flatten (map
    (k:
      let r = (getAttr k records); in
      [{ name = k; value = r.ip; }] ++ (if (r ? aliases) then (map (a: { name = a; value = r.ip; }) r.aliases) else [ ])
    )
    (attrNames records)));
  nameToIp = realNameToIp // (mapAttrs (k: v: getAttr v realNameToIp) aliases);
  realNameToIp6 = listToAttrs (lib.lists.flatten (map
    (k:
      let r = (getAttr k records); in
      if (r ? ip6) then ([{ name = k; value = r.ip6; }] ++ (if (r ? aliases) then (map (a: { name = a; value = r.ip6; }) r.aliases) else [ ])) else [ ]
    )
    (attrNames records)));
  nameToIp6 = realNameToIp6 // (mapAttrs (k: v: getAttr v realNameToIp6) aliases);
  names = attrNames nameToIp;
  names6 = attrNames nameToIp6;
  serverNames = filter (n: (hasAttr n records) && (records."${n}" ? g) && (records."${n}".g == 1)) (attrNames records);
  ipToNames = lib.lists.groupBy (n: getAttr n nameToIp) names;
  ip6ToNames = lib.lists.groupBy (n: getAttr n nameToIp6) names6;
  hosts = mapAttrs (key: value: lib.lists.flatten (map (e: [ e (e + "." + network.domain) ]) value)) ipToNames;
  hosts6 = mapAttrs (key: value: lib.lists.flatten (map (e: [ e (e + "." + network.domain) ]) value)) ip6ToNames;
  ipToIp6 = listToAttrs (lib.lists.flatten (map
    (k:
      let r = (getAttr k records); in
      if (r ? ip6) then [{ name = r.ip; value = r.ip6; }] else [ ]
    )
    (attrNames records)));
  dhcpReservations = lib.lists.flatten [
    (map
      (k:
        let
          r = (getAttr k records);
        in
        if (r ? mac) then [{ name = k; ip = r.ip; mac = r.mac; }] else [ ]
      )
      (attrNames records)
    )
  ];
  dockerOptions = service: [
    "--network=macvlan"
    "--mac-address=${records."${service}".mac}"
    "--hostname=${service}"
    "--ip=${records."${service}".ip}"
    "--ip6=${records."${service}".ip6}"
    "--dns=${records.pihole-1.ip}"
    "--dns=${records.pihole-2.ip}"
    "--dns=${records.pihole-3.ip}"
    "--dns-search=${network.domain}"
  ]
  ++
  (map (n: "--add-host=${n}:${getAttr n nameToIp}") names)
  ++
  (map (n: "--add-host=${n}.${network.domain}:${getAttr n nameToIp}") names)
  ++
  (map (n: "--add-host=${n}:${getAttr n nameToIp6}") names6)
  ++
  (map (n: "--add-host=${n}.${network.domain}:${getAttr n nameToIp6}") names6);
in
{ inherit network group records nameToIp ipToIp6 serverNames hosts hosts6 dhcpReservations dockerOptions; }
