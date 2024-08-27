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
    office = 31;
    study = 33;
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
    switch-d =            { id = 31; mac = "ec:f4:bb:fe:71:f8"; };
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
  } //
  mapAttrs (k: v: { g = group.home-automation; } // v) {
    zigbee =        { id = 6; mac = "b0:a7:32:05:7d:f3"; };
    smartwings-n =  { id = 15; mac = "64:b7:08:17:38:53"; };
    smartwings-s =  { id = 16; mac = "08:3a:8d:b2:be:e3"; };
    somfy =         { id = 17; mac = "00:0e:c6:aa:0a:86"; };
  } //
  mapAttrs (k: v: { g = group.services; } // v) {
    pihole =            { id = 1;   host = "b1"; aliases = [ "dhcp" "dns" ]; };
    ntp =               { id = 2;   host = "b1"; };
    landing =           { id = 3;   host = "b1"; };
    nas =               { id = 10;  host = "c1-1"; dns = "host"; aliases = [ "samba" "smb" ]; };
    syncthing =         { id = 11;  host = "c1-1"; };
    web-swag =          { id = 20;  host = "c1-2"; };
    web-db =            { id = 21;  host = "c1-2"; aliases = [ "db" ]; };
    web-db-admin =      { id = 22;  host = "c1-2"; };
    home-assistant =    { id = 30;  host = "b1"; aliases = [ "homeassistant" "ha" ]; };
    esphome =           { id = 31;  host = "c1-2"; };
    mosquitto =         { id = 32;  host = "b1"; aliases = [ "mqtt" ]; };
    zigbee2mqtt =       { id = 33;  host = "b1"; aliases = [ "z2m" ]; };
    zwave-main =        { id = 40;  host = "pi-67db40"; };
    zwave-upstairs =    { id = 41;  host = "pi-67dbcd"; };
    zwave-basement =    { id = 42;  host = "pi-67dc75"; };
    frigate =           { id = 50;  host = "d1"; };
    plex =              { id = 60;  host = "d1"; };
    sabnzbd =           { id = 70;  host = "c1-1"; };
    transmission =      { id = 71;  host = "c1-1"; };
    prowlarr =          { id = 72;  host = "c1-1"; };
    sonarr =            { id = 73;  host = "c1-1"; };
    radarr =            { id = 74;  host = "c1-1"; };
    lidarr =            { id = 75;  host = "c1-1"; };
    mylar =             { id = 76;  host = "c1-1"; };
    komga =             { id = 77;  host = "c1-1"; };
    minecraft =         { id = 100; host = "c1-2"; };
    userbox-nathaniel = { id = 110; host = "c1-2"; };
  } //
  mapAttrs (k: v: { g = group.vms; } // v) {
    vm1 =               { id = 1; host = "d1"; dns = "host"; };
  } //
  mapAttrs (k: v: { g = group.admin; } // v) {
    c1-imc =      { id = 2; mac = "70:0f:6a:3b:46:01"; };
    d1-bmc =      { id = 4; mac = "18:66:da:b6:45:d8"; };
    josh-pc-bmc = { id = 5; mac = "18:31:bf:cf:20:0b"; };
  } //
  mapAttrs (k: v: { g = group.office; } // v) {
    josh-pc =             { id = 1; mac = "3c:fd:fe:e1:b9:d6"; };
    snap-mac =            { id = 6; mac = "a4:fc:14:0d:f0:ea"; };
    snap-laptop =         { id = 20; mac = "08:92:04:6e:38:61"; };
  } //
  mapAttrs (k: v: { g = group.study; } // v) {
    printer =             { id = 2; mac = "f4:81:39:e4:0a:83"; };
    kitchen-lappy =       { id = 10; mac = "74:e5:f9:e4:3f:59"; };
    kayleigh-lappy-eth =  { id = 20; mac = "b4:45:06:82:81:47"; };
    kayleigh-lappy =      { id = 21; mac = "f0:d4:15:30:c4:a6"; };
    john-lappy-eth =      { id = 30; mac = "b4:45:06:82:81:46"; };
    john-lappy =          { id = 31; mac = "f4:c8:8a:e8:8e:83"; };
    william-lappy-eth =   { id = 40; mac = "b4:45:06:82:7e:db"; };
    william-lappy =       { id = 41; mac = "f4:c8:8a:e8:e0:e0"; };
    lyra-lappy-eth =      { id = 50; mac = "b4:45:06:82:7f:3d"; };
    lyra-lappy =          { id = 51; mac = "f0:d4:15:30:c3:75"; };
    eden-lappy-eth =      { id = 60; mac = "b4:45:06:82:82:e4"; };
    eden-lappy =          { id = 61; mac = "f0:d4:15:30:c5:5a"; };
    hope-lappy-eth =      { id = 70; mac = "f4:c8:8a:e8:e1:a8"; };
    hope-lappy =          { id = 71; mac = "f0:d4:15:30:c5:00"; };
    peter-lappy-eth =     { id = 80; mac = "b4:45:06:82:7e:ff"; };
  } // {
    gr-tv =               { g = 50;  id = 2;  mac = "64:e4:a5:61:30:0b"; };
    lr-shield =           { g = 50;  id = 3;  mac = "00:04:4b:af:f0:0c"; };
    game-room-tv =        { g = 56;  id = 1;  mac = "a0:6a:44:0f:bd:83"; };
    theater-projector =   { g = 59;  id = 1;  mac = "e0:da:dc:17:ec:ef"; };
    theater-preamp =      { g = 59;  id = 2;  mac = "00:1b:7c:0b:21:fb"; };
    theater-shield =      { g = 59;  id = 3;  mac = "00:04:4b:a4:b0:84"; };
    theater-bluray =      { g = 59;  id = 5;  mac = "34:31:7f:dd:db:9b"; };
    camera-garage-s =     { g = 100; id = 16; mac = "9c:8e:cd:3d:72:89"; };
    camera-garage-n =     { g = 100; id = 17; mac = "9c:8e:cd:3d:7c:0b"; };
    camera-back-yard =    { g = 110; id = 16; mac = "9c:8e:cd:3d:72:a6"; };
    camera-driveway =     { g = 113; id = 16; mac = "9c:8e:cd:3d:88:2c"; };
    camera-n-side =       { g = 115; id = 16; mac = "9c:8e:cd:3d:7c:1a"; };
    camera-patio =        { g = 116; id = 16; mac = "fc:5f:49:39:1d:18"; };
    camera-pool =         { g = 117; id = 16; mac = "9c:8e:cd:3d:73:2f"; };
    camera-porch-s =      { g = 118; id = 16; mac = "9c:8e:cd:3d:73:12"; };
    camera-porch-n =      { g = 118; id = 17; mac = "9c:8e:cd:3d:72:f6"; };
    camera-garage-rear =  { g = 119; id = 16; mac = "9c:8e:cd:3d:72:9c"; };
    camera-s-side =       { g = 119; id = 17; mac = "9c:8e:cd:3d:72:c0"; };
    camera-guest-patio =  { g = 120; id = 16; mac = "9c:8e:cd:3d:88:7d"; };
  };
  zeroPad = (s: n: if (stringLength s) >= n then s else (zeroPad ("0" + s) n));
  toHex2 = (x: zeroPad (lib.strings.toLower (lib.trivial.toHexString x)) 2);
  getIp = (name:
    let r = (getAttr name records-conf); in
    if (r ? dns) then (getIp (if (r.dns == "host") then r.host else r.dns)) else lib.concatStrings [ network.prefix (toString r.g) "." (toString r.id) ]
  );
  iot = { 
    server-climate =      { ip = "172.21.1.20"; };
    sprinklers =          { ip = "172.21.2.30"; };
    octoprint =           { ip = "172.21.31.8"; };
    workshop-climate =    { ip = "172.21.32.20"; };
    kitchen-cooktop =     { ip = "172.21.40.2"; };
    ge-unknown-1 =        { ip = "172.21.40.3"; };
    ge-unknown-2 =        { ip = "172.21.40.4"; };
    ge-unknown-3 =        { ip = "172.21.40.5"; };
    ice-maker =           { ip = "172.21.40.6"; };
    frodo =               { ip = "172.21.40.11"; };
    sam =                 { ip = "172.21.40.12"; };
    merry =               { ip = "172.21.40.13"; };
    pippin =              { ip = "172.21.40.14"; };
    theater-remote =      { ip = "172.21.59.7"; };
    theater-climate =     { ip = "172.21.59.20"; };
    ratgdo-1 =            { ip = "172.21.100.11"; };
    ratgdo-2 =            { ip = "172.21.100.12"; };
    ratgdo-3 =            { ip = "172.21.100.13"; };
    ratgdo-4 =            { ip = "172.21.100.14"; };
    balcony-fan =         { ip = "172.21.111.11"; };
    doorbell-front =      { ip = "172.21.118.2"; };
    doorbell-basement =   { ip = "172.21.120.2"; };
  };
  records = (mapAttrs (k: v:
    { ip = getIp k; }
    //
    (if (v ? dns) then {} else { mac = lib.concatStrings [ "00:24:0b:16:" (toHex2 v.g) ":" (toHex2 v.id) ]; })
    //
    v
  ) records-conf) // iot;
  nameToIp = listToAttrs (lib.lists.flatten (map (k:
    let r = (getAttr k records); in
    [ { name = k; value = r.ip; } ] ++ (if (r ? aliases) then (map (a: { name = a; value = r.ip; } ) r.aliases) else [])
  ) (attrNames records)));
  names = attrNames nameToIp;
  serverNames = filter (n: (hasAttr n records) && (records."${n}" ? g) && (records."${n}".g == 1)) (attrNames records);
  ipToNames = lib.lists.groupBy (n: getAttr n nameToIp) names;
  hosts = mapAttrs (key: value: lib.lists.flatten (map (e: [e (e + "." + network.domain)]) value)) ipToNames;
  dhcpReservations = lib.lists.flatten [
    (map
      (k:
        let
          r = (getAttr k records);
        in
        if (r ? mac) then [ { name = k; ip = r.ip; mac = r.mac; } ] else []
      )
      (attrNames records)
    )
  ];
  dockerOptions = service: [
    "--network=macvlan"
    "--mac-address=${records."${service}".mac}"
    "--hostname=${service}"
    "--ip=${records."${service}".ip}"
    "--dns=${records.pihole.ip}"
    "--dns-search=${network.domain}"
  ] ++ (map (n: "--add-host=${n}:${getAttr n nameToIp}") names) ++ (map (n: "--add-host=${n}.${network.domain}:${getAttr n nameToIp}") names);
in { inherit network group records nameToIp serverNames hosts dhcpReservations dockerOptions; }
