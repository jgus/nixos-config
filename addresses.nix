with builtins;
let
  lib = import <nixpkgs/lib>;
  network = rec {
    prefix = "172.22.";
    prefixLength = 16;
    defaultGateway = prefix + "0.1";
    domain = "home.gustafson.me";
  };
  group = {
    network = 0;
    servers = 1;
    home-automation = 2;
    services = 3;
    vms = 4;
    admin = 5;
  };
  records-conf = 
  mapAttrs (k: v: { g = group.network; } // v) {
    router =              { id = 1; mac = "d2:21:f9:d9:78:8c"; aliases = [ "gateway" ]; };
    switch-1g-poe =       { id = 2; mac = "68:d7:9a:23:f1:70"; };
    switch-2g-poe =       { id = 3; mac = "e4:38:83:e8:f3:b1"; };
    switch-10g =          { id = 4; mac = "d8:b3:70:2b:3f:2f"; };
    ap-balcony =          { id = 10; mac = "ac:8b:a9:69:2a:ea"; };
    ap-basement-hall =    { id = 11; mac = "ac:8b:a9:69:36:b1"; };
    ap-bedroom =          { id = 12; mac = "ac:8b:a9:69:3c:bf"; };
    ap-master-closet =    { id = 13; mac = "ac:8b:a9:69:2d:01"; };
    ap-media =            { id = 14; mac = "ac:8b:a9:69:33:f0"; };
    ap-mudroom =          { id = 15; mac = "ac:8b:a9:69:3b:fc"; };
    ap-office =           { id = 16; mac = "ac:8b:a9:69:31:52"; };
    ap-server =           { id = 17; mac = "24:5a:4c:5e:bc:f6"; };
    switch-admin =        { id = 20; mac = "80:2a:a8:9c:79:53"; };
    switch-gr =           { id = 21; mac = "f4:e2:c6:59:a1:7d"; };
    switch-heater =       { id = 22; mac = "f4:e2:c6:59:9e:37"; };
    switch-office =       { id = 23; mac = "f4:e2:c6:59:9c:76"; };
    switch-study =        { id = 24; mac = "f4:e2:c6:59:9c:4d"; };
    switch-c =            { id = 30; mac = "f8:c2:88:23:8c:10"; };
  } //
  mapAttrs (k: v: { g = group.servers; } // v) {
    b1 =        { id = 1; };
    c1-1 =      { id = 2; };
    c1-2 =      { id = 3; };
    d1 =        { id = 4; };
    pi-67cba1 = { id = 65; aliases = [ "theater-pi" "theater-cec" ]; };
    pi-67db40 = { id = 66; };
    pi-67dbcd = { id = 67; };
    pi-67dc75 = { id = 68; };
  };
  zeroPad = (s: n: if (stringLength s) >= n then s else (zeroPad ("0" + s) n));
  toHex2 = (x: zeroPad (lib.strings.toLower (lib.trivial.toHexString x)) 2);
  records = listToAttrs (map (k:
    let r = (getAttr k records-conf); in
    {
      name = k;
      value = {
        ip = lib.concatStrings [ network.prefix (toString r.g) "." (toString r.id) ];
        mac = lib.concatStrings [ "00:24:0b:16:" (toHex2 r.g) ":" (toHex2 r.id) ];
      } // r;
    }
  ) (attrNames records-conf));
  servers = {
    b1 =        { mac = "00:24:0b:16:01:01";  ip = "172.22.1.1"; };
    c1-1 =      { mac = "00:24:0b:16:01:02";  ip = "172.22.1.2"; };
    c1-2 =      { mac = "00:24:0b:16:01:03";  ip = "172.22.1.3"; };
    d1 =        { mac = "00:24:0b:16:01:04";  ip = "172.22.1.4"; };
    pi-67cba1 = { mac = "00:24:0b:16:01:41";  ip = "172.22.1.65"; aliases = [ "theater-pi" "theater-cec" ]; };
    pi-67db40 = { mac = "00:24:0b:16:01:42";  ip = "172.22.1.66"; };
    pi-67dbcd = { mac = "00:24:0b:16:01:43";  ip = "172.22.1.67"; };
    pi-67dc75 = { mac = "00:24:0b:16:01:44";  ip = "172.22.1.68"; };
  };
  statics = { 
    router =              { mac = "d2:21:f9:d9:78:8c"; ip = "172.22.0.1"; aliases = [ "gateway" ]; };
    switch-1g-poe =       { mac = "68:d7:9a:23:f1:70"; ip = "172.22.0.2"; };
    switch-2g-poe =       { mac = "e4:38:83:e8:f3:b1"; ip = "172.22.0.3"; };
    switch-10g =          { mac = "d8:b3:70:2b:3f:2f"; ip = "172.22.0.4"; };
    ap-balcony =          { mac = "ac:8b:a9:69:2a:ea"; ip = "172.22.0.10"; };
    ap-basement-hall =    { mac = "ac:8b:a9:69:36:b1"; ip = "172.22.0.11"; };
    ap-bedroom =          { mac = "ac:8b:a9:69:3c:bf"; ip = "172.22.0.12"; };
    ap-master-closet =    { mac = "ac:8b:a9:69:2d:01"; ip = "172.22.0.13"; };
    ap-media =            { mac = "ac:8b:a9:69:33:f0"; ip = "172.22.0.14"; };
    ap-mudroom =          { mac = "ac:8b:a9:69:3b:fc"; ip = "172.22.0.15"; };
    ap-office =           { mac = "ac:8b:a9:69:31:52"; ip = "172.22.0.16"; };
    ap-server =           { mac = "24:5a:4c:5e:bc:f6"; ip = "172.22.0.17"; };
    switch-admin =        { mac = "80:2a:a8:9c:79:53"; ip = "172.22.0.20"; };
    switch-gr =           { mac = "f4:e2:c6:59:a1:7d"; ip = "172.22.0.21"; };
    switch-heater =       { mac = "f4:e2:c6:59:9e:37"; ip = "172.22.0.22"; };
    switch-office =       { mac = "f4:e2:c6:59:9c:76"; ip = "172.22.0.23"; };
    switch-study =        { mac = "f4:e2:c6:59:9c:4d"; ip = "172.22.0.24"; };
    switch-c =            { mac = "f8:c2:88:23:8c:10"; ip = "172.22.0.30"; };
    c1-imc =              { mac = "70:0f:6a:3b:46:01"; ip = "172.22.5.2"; };
    d1-bmc =              { mac = "18:66:da:b6:45:d8"; ip = "172.22.5.4"; };
    zigbee =              { mac = "b0:a7:32:05:7d:f3"; ip = "172.22.2.6"; };
    smartwings-n =        { mac = "64:b7:08:17:38:53"; ip = "172.22.2.15"; };
    smartwings-s =        { mac = "08:3a:8d:b2:be:e3"; ip = "172.22.2.16"; };
    somfy =               { mac = "00:0e:c6:aa:0a:86"; ip = "172.22.2.17"; };
    josh-pc =             { mac = "3c:fd:fe:e1:b9:d6"; ip = "172.22.31.1"; };
    josh-pc-bmc =         { mac = "18:31:bf:cf:20:0b"; ip = "172.22.31.3"; };
    snap-mac =            { mac = "a4:fc:14:0d:f0:ea"; ip = "172.22.31.6"; };
    snap-laptop =         { mac = "08:92:04:6e:38:61"; ip = "172.22.31.20"; };
    printer =             { mac = "f4:81:39:e4:0a:83"; ip = "172.22.33.2"; };
    kitchen-lappy =       { mac = "74:e5:f9:e4:3f:59"; ip = "172.22.33.10"; };
    kayleigh-lappy-eth =  { mac = "b4:45:06:82:81:47"; ip = "172.22.33.20"; };
    kayleigh-lappy =      { mac = "f0:d4:15:30:c4:a6"; ip = "172.22.33.21"; };
    john-lappy-eth =      { mac = "b4:45:06:82:81:46"; ip = "172.22.33.30"; };
    john-lappy =          { mac = "f4:c8:8a:e8:8e:83"; ip = "172.22.33.31"; };
    william-lappy-eth =   { mac = "b4:45:06:82:7e:db"; ip = "172.22.33.40"; };
    william-lappy =       { mac = "f4:c8:8a:e8:e0:e0"; ip = "172.22.33.41"; };
    lyra-lappy-eth =      { mac = "b4:45:06:82:7f:3d"; ip = "172.22.33.50"; };
    lyra-lappy =          { mac = "f0:d4:15:30:c3:75"; ip = "172.22.33.51"; };
    eden-lappy-eth =      { mac = "b4:45:06:82:82:e4"; ip = "172.22.33.60"; };
    eden-lappy =          { mac = "f0:d4:15:30:c5:5a"; ip = "172.22.33.61"; };
    hope-lappy-eth =      { mac = "f4:c8:8a:e8:e1:a8"; ip = "172.22.33.70"; };
    hope-lappy =          { mac = "f0:d4:15:30:c5:00"; ip = "172.22.33.71"; };
    peter-lappy-eth =     { mac = "b4:45:06:82:7e:ff"; ip = "172.22.33.80"; };
    gr-tv =               { mac = "64:e4:a5:61:30:0b"; ip = "172.22.50.2"; };
    lr-shield =           { mac = "00:04:4b:af:f0:0c"; ip = "172.22.50.3"; };
    game-room-tv =        { mac = "a0:6a:44:0f:bd:83"; ip = "172.22.56.1"; };
    theater-projector =   { mac = "e0:da:dc:17:ec:ef"; ip = "172.22.59.1"; };
    theater-preamp =      { mac = "00:1b:7c:0b:21:fb"; ip = "172.22.59.2"; };
    theater-shield =      { mac = "00:04:4b:a4:b0:84"; ip = "172.22.59.3"; };
    theater-bluray =      { mac = "34:31:7f:dd:db:9b"; ip = "172.22.59.5"; };
    camera-garage-s =     { mac = "9c:8e:cd:3d:72:89"; ip = "172.22.100.16"; };
    camera-garage-n =     { mac = "9c:8e:cd:3d:7c:0b"; ip = "172.22.100.17"; };
    camera-back-yard =    { mac = "9c:8e:cd:3d:72:a6"; ip = "172.22.110.16"; };
    camera-driveway =     { mac = "9c:8e:cd:3d:88:2c"; ip = "172.22.113.16"; };
    camera-n-side =       { mac = "9c:8e:cd:3d:7c:1a"; ip = "172.22.115.16"; };
    camera-patio =        { mac = "fc:5f:49:39:1d:18"; ip = "172.22.116.16"; };
    camera-pool =         { mac = "9c:8e:cd:3d:73:2f"; ip = "172.22.117.16"; };
    camera-porch-s =      { mac = "9c:8e:cd:3d:73:12"; ip = "172.22.118.16"; };
    camera-porch-n =      { mac = "9c:8e:cd:3d:72:f6"; ip = "172.22.118.17"; };
    camera-garage-rear =  { mac = "9c:8e:cd:3d:72:9c"; ip = "172.22.119.16"; };
    camera-s-side =       { mac = "9c:8e:cd:3d:72:c0"; ip = "172.22.119.17"; };
    camera-guest-patio =  { mac = "9c:8e:cd:3d:88:7d"; ip = "172.22.120.16"; };
  };
  staticsIot = { 
    server-climate =      { mac = "94:24:b8:6c:0f:41"; ip = "172.21.1.20"; };
    sprinklers =          { mac = "48:e7:29:70:77:02"; ip = "172.21.2.30"; };
    octoprint =           { mac = "b8:27:eb:e8:df:ae"; ip = "172.21.31.8"; };
    workshop-climate =    { mac = "94:24:b8:6d:47:92"; ip = "172.21.32.20"; };
    kitchen-cooktop =     { mac = "68:a4:0e:8b:bf:2b"; ip = "172.21.40.2"; };
    ge-unknown-1 =        { mac = "bc:c7:da:16:46:d6"; ip = "172.21.40.3"; };
    ge-unknown-2 =        { mac = "d8:28:c9:f2:cd:e6"; ip = "172.21.40.4"; };
    ge-unknown-3 =        { mac = "38:7c:76:b3:93:dc"; ip = "172.21.40.5"; };
    ice-maker =           { mac = "d8:28:c9:f3:89:f4"; ip = "172.21.40.6"; };
    frodo =               { mac = "70:c9:32:29:fd:a9"; ip = "172.21.40.11"; };
    sam =                 { mac = "70:c9:32:3e:8f:ce"; ip = "172.21.40.12"; };
    merry =               { mac = "70:c9:32:3e:90:2f"; ip = "172.21.40.13"; };
    pippin =              { mac = "70:c9:32:3e:90:9d"; ip = "172.21.40.14"; };
    theater-remote =      { mac = "ac:ff:00:00:02:6b"; ip = "172.21.59.7"; };
    theater-climate =     { mac = "94:24:b8:6c:10:13"; ip = "172.21.59.20"; };
    ratgdo-1 =            { mac = "08:3a:8d:f6:14:fa"; ip = "172.21.100.11"; };
    ratgdo-2 =            { mac = "08:3a:8d:f9:ed:1f"; ip = "172.21.100.12"; };
    ratgdo-3 =            { mac = "48:3f:da:ca:04:e7"; ip = "172.21.100.13"; };
    ratgdo-4 =            { mac = "08:f9:e0:4b:0a:2d"; ip = "172.21.100.14"; };
    balcony-fan =         { mac = "1c:90:ff:8a:6e:22"; ip = "172.21.111.11"; };
    doorbell-front =      { mac = "9c:8e:cd:3c:35:8f"; ip = "172.21.118.2"; };
    doorbell-basement =   { mac = "9c:8e:cd:3c:e0:79"; ip = "172.21.120.2"; };
  };
  services = {
    pihole =            { mac = "00:24:0b:51:00:00"; ip = "172.22.3.1";   host = "b1"; dns = "own"; aliases = [ "dhcp" "dns" ]; };

    ntp =               { mac = "00:24:0b:51:00:10"; ip = "172.22.3.2";   host = "d1"; dns = "own"; };

    landing =           { mac = "00:24:0b:51:01:10"; ip = "172.22.3.3";   host = "d1"; dns = "own"; };

    nas =               { mac = "00:24:0b:51:03:10"; ip = "172.22.3.10";  host = "d1"; dns = "host"; aliases = [ "samba" "smb" "nfs" ]; };
    syncthing =         { mac = "00:24:0b:51:03:20"; ip = "172.22.3.11";  host = "d1"; dns = "own"; };

    web-swag =          { mac = "00:24:0b:51:04:10"; ip = "172.22.3.20";  host = "d1"; dns = "host"; };
    web-db =            { mac = "00:24:0b:51:04:20"; ip = "172.22.3.21";  host = "d1"; dns = "host"; };
    web-db-admin =      { mac = "00:24:0b:51:04:20"; ip = "172.22.3.22";  host = "d1"; dns = "host"; };

    homeassistant =     { mac = "00:24:0b:51:0a:10"; ip = "172.22.3.30";  host = "d1"; dns = "host"; aliases = [ "ha" ]; };
    esphome =           { mac = "00:24:0b:51:0a:20"; ip = "172.22.3.31";  host = "d1"; dns = "host"; };
    mosquitto =         { mac = "00:24:0b:51:0a:30"; ip = "172.22.3.32";  host = "d1"; dns = "own"; aliases = [ "mqtt" ]; };
    zigbee2mqtt =       { mac = "00:24:0b:51:0a:40"; ip = "172.22.3.33";  host = "d1"; dns = "host"; };
    zwave-main =        { mac = "00:24:0b:51:0a:51"; ip = "172.22.3.40";  host = "pi-67db40"; dns = "host"; };
    zwave-upstairs =    { mac = "00:24:0b:51:0a:52"; ip = "172.22.3.41";  host = "pi-67dbcd"; dns = "host"; };
    zwave-basement =    { mac = "00:24:0b:51:0a:53"; ip = "172.22.3.42";  host = "pi-67dc75"; dns = "host"; };

    frigate =           { mac = "00:24:0b:51:0f:10"; ip = "172.22.3.50";  host = "d1"; dns = "host"; };

    plex =              { mac = "00:24:0b:51:0e:10"; ip = "172.22.3.60";  host = "d1"; dns = "own"; };

    sabnzbd =           { mac = "00:24:0b:51:09:10"; ip = "172.22.3.70";  host = "d1"; dns = "host"; };
    transmission =      { mac = "00:24:0b:51:09:20"; ip = "172.22.3.71";  host = "d1"; dns = "host"; };
    prowlarr =          { mac = "00:24:0b:51:09:30"; ip = "172.22.3.72";  host = "d1"; dns = "host"; };
    sonarr =            { mac = "00:24:0b:51:09:40"; ip = "172.22.3.73";  host = "d1"; dns = "host"; };
    radarr =            { mac = "00:24:0b:51:09:50"; ip = "172.22.3.74";  host = "d1"; dns = "host"; };
    lidarr =            { mac = "00:24:0b:51:09:60"; ip = "172.22.3.75";  host = "d1"; dns = "host"; };
    mylar =             { mac = "00:24:0b:51:09:70"; ip = "172.22.3.76";  host = "d1"; dns = "host"; };
    komga =             { mac = "00:24:0b:51:09:80"; ip = "172.22.3.77";  host = "d1"; dns = "host"; };

    minecraft =         { mac = "00:24:0b:51:10:10"; ip = "172.22.3.100"; host = "d1"; dns = "host"; };

    userbox-nathaniel = { mac = "00:24:0b:51:11:10"; ip = "172.22.3.110"; host = "d1"; dns = "host"; };
  };
  vms = {
    vm1 =               { mac = "00:24:0b:51:40:10"; ip = "172.22.4.1";   host = "d1"; dns = "host"; };
  };
  serversAndStatics = servers // statics // staticsIot;
  servicesAndVms = services // vms;
  nameIpPairs = lib.lists.flatten [
    (map
      (k: 
        let
          m = (getAttr k serversAndStatics);
          ip = m.ip;
        in
        [ { name = k; ip = ip; } ] ++ (map (alias: { name = alias; ip = ip; }) (if (m ? aliases) then m.aliases else []))
      )
      (attrNames serversAndStatics)
    )
    (map
      (k: 
        let
          s = (getAttr k servicesAndVms);
          ip = if (s.dns == "own") then s.ip else if (s.dns == "host") then (getAttr s.host servers).ip else (getAttr s.dns servers).ip;
        in
        [ { name = k; ip = ip; } ] ++ (map (alias: { name = alias; ip = ip; }) (if (s ? aliases) then s.aliases else []))
      )
      (attrNames servicesAndVms)
    )
  ];
  names = map (p: p.name) nameIpPairs;
  nameToIp = listToAttrs (map (p: { name = p.name; value = p.ip; }) nameIpPairs);
  ipToNames = lib.lists.groupBy (n: getAttr n nameToIp) names;
  hosts = mapAttrs (key: value: lib.lists.flatten (map (e: [e (e + "." + network.domain)]) value)) ipToNames;
  dhcpReservations = lib.lists.flatten [
    (map
      (k:
        let
          s = (getAttr k serversAndStatics);
        in
        [ { name = k; ip = s.ip; mac = s.mac; } ]
      )
      (attrNames serversAndStatics)
    )
    (map
      (k: 
        let
          s = (getAttr k servicesAndVms);
        in
        if (s.dns == "own") then [ { name = k; ip = s.ip; mac = s.mac; } ] else []
      )
      (attrNames servicesAndVms)
    )
  ];
in { inherit network records servers services vms nameToIp hosts dhcpReservations; }
