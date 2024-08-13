with builtins;
let
  lib = import <nixpkgs/lib>;
  network = {
    defaultGateway = "172.22.0.1";
    prefixLength = 16;
    domain = "home.gustafson.me";
  };
  machines = {
    b1 =        { mac = "00:24:0b:01:b1:10";  ip = "172.22.1.36"; };
    c1-1 =      { mac = "00:24:0b:01:c1:10";  ip = "172.22.1.30"; };
    c1-2 =      { mac = "00:24:0b:01:c1:20";  ip = "172.22.1.32"; };
    d1 =        { mac = "00:24:0b:01:d1:10";  ip = "172.22.1.11"; };
    pi-67db40 = { mac = "d8:3a:dd:67:db:40";  ip = "172.22.2.10"; };
    pi-67dbcd = { mac = "d8:3a:dd:67:db:cd";  ip = "172.22.2.11"; };
    pi-67dc75 = { mac = "d8:3a:dd:67:dc:75";  ip = "172.22.2.12"; };
    pi-67cba1 = { mac = "d8:3a:dd:67:cb:a1";  ip = "172.22.2.8"; aliases = [ "theater-pi" "theater-cec" ]; };
  };
  services = {
    pihole =            { mac = "00:24:0b:51:00:00"; ip = "172.22.3.1";   host = "b1"; dns = "own"; };

    ntp =               { mac = "00:24:0b:51:00:10"; ip = "172.22.3.2";   host = "d1"; dns = "own"; };

    landing =           { mac = "00:24:0b:51:01:10"; ip = "172.22.3.3";   host = "d1"; dns = "own"; };

    nas =               { mac = "00:24:0b:51:03:10"; ip = "172.22.3.10";  host = "d1"; dns = "own"; };
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
  servicesAndVms = services // vms;
  pairs = lib.lists.flatten [
    (map
      (k: 
        let
          m = (getAttr k machines);
          ip = m.ip;
        in
        [ { name = k; ip = ip; } ] ++ (map (alias: { name = alias; ip = ip; }) (if (m ? aliases) then m.aliases else []))
      )
      (attrNames machines)
    )
    (map
      (k: 
        let
          s = (getAttr k servicesAndVms);
          ip = if (s.dns == "own") then s.ip else if (s.dns == "host") then (getAttr s.host machines).ip else (getAttr s.dns machines).ip;
        in
        [ { name = k; ip = ip; } ] ++ (map (alias: { name = alias; ip = ip; }) (if (s ? aliases) then s.aliases else []))
      )
      (attrNames servicesAndVms)
    )
  ];
  names = map (p: p.name) pairs;
  nameToIp = listToAttrs (map (p: { name = p.name; value = p.ip; }) pairs);
  ipToNames = lib.lists.groupBy (n: getAttr n nameToIp) names;
  hosts = mapAttrs (key: value: lib.lists.flatten (map (e: [e (e + "." + network.domain)]) value)) ipToNames;
in { inherit network machines services vms hosts; }
