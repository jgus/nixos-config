{ config, ... }:
{
  homelab.network = {
    net4 = "172.22.0.0/16";
    defaultGateway = "172.22.0.1";
    net6 = "2001:55d:b00b:1::/64";
    local6 = "2001:55d:b00b::/48";
    domain = "home.gustafson.me";
    assignedMacBase = "00:24:0b:16:00:00";
    dnsServers = [ "pihole-1" "pihole-2" "pihole-3" ];
    publicDomain = "gustafson.me";

    hosts = {
      network = {
        id = 0;
        hosts = {
          router = { id = 1; mac = "d2:21:f9:d9:78:8c"; };
          gateway = { alias = "router"; };
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
          pi-be4492 = { id = 101; mac = "dc:a6:32:be:44:92"; };
          n-kvm = { alias = "pi-be4492"; };
        };
      };

      servers = {
        id = 1;
        assignMac = true;
        assignIp6 = true;
        hosts = {
          b1 = { id = 1; };
          c1-1 = { id = 2; };
          c1-2 = { id = 3; };
          d1 = { id = 4; };
          pi-67cba1 = { id = 65; };
          theater-pi = { alias = "pi-67cba1"; };
          theater-cec = { alias = "pi-67cba1"; };
        };
      };

      home-automation = {
        id = 2;
        hosts = {
          sensor-hub-1 = { id = 2; mac = "70:b8:f6:9b:f3:83"; };
          zigbee-radio = { id = 6; mac = "ec:c9:ff:bc:7c:ef"; };
          zwave-radio-main = { id = 7; mac = "b0:b2:1c:93:62:4f"; };
          zwave-radio-upstairs = { id = 8; mac = "a0:b7:65:fa:bf:03"; };
          zwave-radio-basement = { id = 9; mac = "a0:b7:65:fa:be:97"; };
          zwave-radio-north = { id = 10; mac = "f8:b3:b7:c4:aa:d7"; };
          somfy = { id = 17; mac = "00:0e:c6:aa:0a:86"; };
        };
      };

      services = {
        id = 3;
        assignMac = true;
        assignIp6 = true;
        hosts = {
          # Network
          pihole-1 = { id = 1; host = "b1"; };
          dhcp-1 = { alias = "pihole-1"; };
          dns-1 = { alias = "pihole-1"; };
          pihole = { alias = "pihole-1"; };
          dhcp = { alias = "pihole-1"; };
          dns = { alias = "pihole-1"; };
          ntp = { id = 2; host = "b1"; };
          pihole-2 = { id = 4; host = "c1-1"; };
          dhcp-2 = { alias = "pihole-2"; };
          dns-2 = { alias = "pihole-2"; };
          pihole-3 = { id = 5; host = "d1"; };
          dhcp-3 = { alias = "pihole-3"; };
          dns-3 = { alias = "pihole-3"; };
          cloudflared = { id = 6; host = "c1-2"; };
          echo = { id = 7; host = "d1"; };

          # Storage
          samba = { id = 10; host = "c1-1"; };
          smb = { alias = "samba"; };
          nas = { alias = "samba"; };
          samba-c1-2 = { id = 11; host = "c1-2"; };
          garage = { id = 12; host = "d1"; };
          owncloud = { id = 13; host = "c1-1"; };
          drive = { alias = "owncloud"; };
          owncloud-db = { id = 14; host = "c1-1"; };
          owncloud-redis = { id = 15; host = "c1-1"; };
          onlyoffice = { id = 16; host = "c1-2"; };
          office = { alias = "onlyoffice"; };

          # Web
          web = { id = 20; host = "c1-2"; };
          journal = { id = 21; host = "c1-2"; };
          journal-db = { id = 22; host = "c1-2"; };
          joyfulsong = { id = 23; host = "c1-2"; };
          joyfulsong-db = { id = 24; host = "c1-2"; };
          searxng = { id = 28; host = "c1-2"; };
          searxng-mcp = { id = 29; host = "c1-2"; };

          # Home Automation
          home-assistant = { id = 30; host = "b1"; };
          homeassistant = { alias = "home-assistant"; };
          ha = { alias = "home-assistant"; };
          esphome = { id = 31; host = "c1-2"; };
          mosquitto = { id = 32; host = "b1"; };
          mqtt = { alias = "mosquitto"; };
          zigbee2mqtt = { id = 33; host = "b1"; };
          z2m = { alias = "zigbee2mqtt"; };
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
          calibre = { id = 64; host = "c1-2"; };
          audiobookshelf = { id = 65; host = "c1-2"; };

          # AI
          large-model-proxy = { id = 80; host = "d1"; };
          comfyui = { alias = "large-model-proxy"; };
          ollama = { id = 81; host = "d1"; };
          qdrant = { id = 82; host = "d1"; };
          open-webui = { id = 88; host = "d1"; };

          # Other
          minecraft = { id = 100; host = "c1-2"; };
          code-server = { id = 101; host = "c1-2"; };
        };
      };

      vms = {
        id = 4;
        assignMac = true;
        assignIp6 = true;
        hosts = { };
      };

      admin = {
        id = 5;
        hosts = {
          c1-imc-1 = { id = 2; mac = "70:0f:6a:3b:46:01"; };
          c1-imc = { alias = "c1-imc-1"; };
          c1-imc-2 = { id = 3; mac = "70:79:b3:09:49:16"; };
          c1-bmc-1 = { id = 12; mac = "b4:de:31:bd:a8:be"; };
          c1-bmc-2 = { id = 13; mac = "00:be:75:e0:a2:3e"; };
          d1-bmc = { id = 4; mac = "18:66:da:b6:45:d8"; };
          josh-pc-bmc = { id = 5; mac = "18:31:bf:cf:20:0b"; };
          server-ups = { id = 6; mac = "28:29:86:7f:bf:21"; };
        };
      };

      office = {
        id = 31;
        hosts = {
          josh-pc = { id = 1; mac = "3c:fd:fe:e1:b9:d6"; };
        };
      };

      study = {
        id = 33;
        hosts = {
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
        };
      };

      other = {
        id = 99;
        hosts = {
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
      };
    };

    vlans = {
      iot = {
        vlanId = 3;
        net4 = "172.21.0.0/16";
        hosts = {
          other = {
            id = 99;
            hosts = {
              server-climate = { g = 1; id = 20; };
              sprinklers = { g = 2; id = 30; };
              octoprint = { g = 31; id = 8; };
              workshop-climate = { g = 32; id = 20; };
              ratgdo-1 = { g = 100; id = 11; };
              ratgdo-2 = { g = 100; id = 12; };
              ratgdo-3 = { g = 100; id = 13; };
              ratgdo-4 = { g = 100; id = 14; };
              kitchen-cooktop = { g = 40; id = 2; };
              ge-unknown-1 = { g = 40; id = 3; };
              ge-unknown-2 = { g = 40; id = 4; };
              ge-unknown-3 = { g = 40; id = 5; };
              ice-maker = { g = 40; id = 6; };
              frodo = { g = 40; id = 11; };
              sam = { g = 40; id = 12; };
              merry = { g = 40; id = 13; };
              pippin = { g = 40; id = 14; };
              theater-remote = { g = 59; id = 7; };
              theater-uc-remote = { g = 59; id = 8; };
              theater-climate = { g = 59; id = 20; };
              balcony-fan = { g = 111; id = 11; };
              doorbell-front = { g = 118; id = 2; };
              doorbell-basement = { g = 120; id = 2; };
            };
          };
        };
      };

      download = {
        vlanId = 4;
        net4 = "172.20.0.0/16";
        hosts = {
          services = {
            id = 3;
            hosts = {
              sabnzbd = { id = 70; host = "c1-2"; };
              qbittorrent = { id = 71; host = "c1-2"; };
              prowlarr = { id = 72; host = "c1-2"; };
              sonarr = { id = 73; host = "c1-2"; };
              radarr = { id = 74; host = "c1-2"; };
              lidarr = { id = 75; host = "c1-2"; };
              kapowarr = { id = 76; host = "c1-2"; };
              flaresolverr = { id = 77; host = "c1-2"; };
              lazylibrarian = { id = 78; host = "c1-2"; };
            };
          };
        };
      };

      dmz = {
        vlanId = 5;
        net4 = "172.19.0.0/16";
        net6 = "2001:55d:b00b:5::/64";
        hosts = { };
      };
    };
  };

  assertions =
    with config.homelab.network;
    [
      # Host IP4 Tests
      {
        assertion = hosts.other.hosts.gr-tv.ip4 == "172.22.50.2";
        message = "host.ip4: primary network, host g override";
      }
      {
        assertion = hosts.servers.hosts.b1.ip4 == "172.22.1.1";
        message = "host.ip4: primary network, group inherited";
      }
      {
        assertion = vlans.iot.hosts.other.hosts.server-climate.ip4 == "172.21.1.20";
        message = "host.ip4: VLAN, host g override";
      }
      {
        assertion = vlans.download.hosts.services.hosts.sabnzbd.ip4 == "172.20.3.70";
        message = "host.ip4: VLAN, group inherited";
      }

      # Host MAC Tests
      {
        assertion = hosts.servers.hosts.b1.mac == "00:24:0b:16:01:01";
        message = "host.mac: assignMac=true, group inherited, computed";
      }
      {
        assertion = hosts.other.hosts.gr-tv.mac == "64:e4:a5:61:30:0b";
        message = "host.mac: assignMac=false (no assignMac), host g override, explicit";
      }
      {
        assertion = hosts.network.hosts.router.mac == "d2:21:f9:d9:78:8c";
        message = "host.mac: assignMac=false (no assignMac), group inherited, explicit";
      }

      # Host IP6 Tests
      {
        assertion = hosts.servers.hosts.b1.ip6 == "2001:55d:b00b:1:224:bff:fe16:101";
        message = "host.ip6: primary network, assignIp6=true, mac computed";
      }
      {
        assertion = hosts.home-automation.hosts.sensor-hub-1.ip6 == null;
        message = "host.ip6: primary network, assignIp6=false, mac explicit";
      }
      {
        assertion = hosts.network.hosts.router.ip6 == null;
        message = "host.ip6: primary network, assignIp6=false, mac explicit";
      }
      {
        assertion = vlans.iot.hosts.other.hosts.server-climate.ip6 == null;
        message = "host.ip6: VLAN, no net6";
      }

      # Host G Tests
      {
        assertion = hosts.other.hosts.gr-tv.g == 50;
        message = "host.g: host g override";
      }
      {
        assertion = hosts.servers.hosts.b1.g == 1;
        message = "host.g: group inherited";
      }

      # Network-level Tests
      {
        assertion = defaultGateway == "172.22.0.1";
        message = "network.defaultGateway";
      }
      {
        assertion = vlans.iot.defaultGateway == "172.21.0.1";
        message = "vlan.defaultGateway";
      }
    ];
}
