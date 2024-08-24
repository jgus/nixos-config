{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  pw = import ./.secrets/passwords.nix;
  configFile = pkgs.writeText "config.yml" ''
    # logger:
    #   default: debug
    mqtt:
      host: mqtt.home.gustafson.me
      user: frigate
      password: ${pw.mqtt.frigate}
    objects:
      track:
        - person
        - car
      filters:
        person:
          min_score: 0.5
          threshold: 0.8
    audio:
      enabled: True
    detectors:
      coral1:
        type: edgetpu
        device: pci:0
      coral2:
        type: edgetpu
        device: pci:1
      # coral3:
      #   type: edgetpu
      #   device: usb:0
      # coral4:
      #   type: edgetpu
      #   device: usb:1
    record:
      retain:
        days: 30
        mode: motion
      events:
        retain:
          default: 180
          mode: active_objects
    ffmpeg:
      hwaccel_args: preset-nvidia-h264
      output_args:
        record: -f segment -segment_time 10 -segment_format mp4 -reset_timestamps 1 -strftime 1 -c copy
    birdseye:
      enabled: True
      mode: objects
      width: 3840
      height: 2160
      restream: True
    cameras:
      doorbell-front:
        ffmpeg:
          inputs:
            - path: rtsp://admin:${pw.doorbell}@doorbell-front.home.gustafson.me:554
              roles:
                - detect
                - audio
                - record
        record:
          enabled: True
        snapshots:
          enabled: True
        detect:
          width: 2560
          height: 1920
        motion:
          mask:
            - 2560,52,2560,0,1970,0,1970,52
            - 764,226,2560,641,2560,880,2397,886,2135,1057,1418,1119,725,1132
        zones:
          porch:
            coordinates: 0,1920,0,1457,860,1465,1039,1335,1818,1291,2275,1280,2560,1164,2560,1920
          front_yard:
            coordinates: 2560,919,2428,909,2218,1047,1854,1078,1351,1112,738,1119,766,1436,849,1436,836,1304,1574,1283,1995,1249,2384,1205,2560,1143
        objects:
          filters:
            car:
              mask:
                - 764,226,2560,641,2560,880,2397,886,2135,1057,1418,1119,725,1132
            person:
              mask:
                - 764,226,2560,641,2560,880,2397,886,2135,1057,1418,1119,725,1132
      camera-porch-n:
        ffmpeg:
          inputs:
            - path: rtsp://admin:${pw.camera}@camera-porch-n.home.gustafson.me:554
              roles:
                - detect
                - audio
                - record
        record:
          enabled: True
        snapshots:
          enabled: True
        detect:
          width: 3840
          height: 2160
        motion:
          mask:
            - 2596,188,3696,188,3696,80,2596,80
            - 3485,0,3840,0,3840,225
            - 985,0,305,0,375,209
        zones:
          porch:
            coordinates: 573,1815,0,1223,0,315,293,72,551,592,940,1207
          front_yard:
            coordinates: 1053,2160,3840,2160,3840,0,983,0,543,144,405,237,888,1117,1119,1255,716,1899
        objects:
          filters:
            car:
              mask:
                - 3485,0,3840,0,3840,225
                - 985,0,305,0,375,209
            person:
              mask:
                - 3485,0,3840,0,3840,225
                - 985,0,305,0,375,209
      camera-porch-s:
        ffmpeg:
          inputs:
            - path: rtsp://admin:${pw.camera}@camera-porch-s.home.gustafson.me:554
              roles:
                - detect
                - audio
                - record
        record:
          enabled: True
        snapshots:
          enabled: True
        detect:
          width: 3840
          height: 2160
        motion:
          mask:
            - 2596,188,3696,188,3696,80,2596,80
            - 826,0,245,0,401,284
        zones:
          porch:
            coordinates: 1620,0,3840,0,3840,2160,824,2160,2051,704,1670,537
          front_yard:
            coordinates: 666,836,347,0,1590,0,1616,469,1564,674,1905,824,1219,1662
        objects:
          filters:
            car:
              mask:
                - 826,0,245,0,401,284
            person:
              mask:
                - 826,0,245,0,401,284
      camera-driveway:
        ffmpeg:
          inputs:
            - path: rtsp://admin:${pw.camera}@camera-driveway.home.gustafson.me:554
              roles:
                - detect
                - audio
                - record
        record:
          enabled: True
        snapshots:
          enabled: True
        detect:
          width: 3840
          height: 2160
        motion:
          mask:
            - 2596,188,3696,188,3696,80,2596,80
            - 3840,0,3840,874,2914,419,1969,134,1249,247,463,497,399,0
        zones:
          front_yard:
            coordinates: 3481,686,3108,499,2821,652,2908,902,3299,1183
          driveway:
            coordinates: 2867,2160,3313,1195,2908,912,2813,650,3104,499,2202,188,1632,193,499,505,772,1426,582,1522,969,2160
        objects:
          filters:
            car:
              mask:
                - 3840,0,3840,874,2914,419,1969,134,1249,247,463,497,399,0
            person:
              mask:
                - 3840,0,3840,874,2914,419,1969,134,1249,247,463,497,399,0
      camera-garage-n:
        ffmpeg:
          inputs:
            - path: rtsp://admin:${pw.camera}@camera-garage-n.home.gustafson.me:554
              roles:
                - detect
                - audio
                - record
        record:
          enabled: True
        snapshots:
          enabled: True
        detect:
          width: 3840
          height: 2160
        motion:
          mask:
            - 2596,188,3696,188,3696,80,2596,80
        zones:
          garage:
            coordinates: 0,2160,3840,2160,3840,1021,2292,26,2240,547,816,920,598,0,0,0
      camera-garage-s:
        ffmpeg:
          inputs:
            - path: rtsp://admin:${pw.camera}@camera-garage-s.home.gustafson.me:554
              roles:
                - detect
                - audio
                - record
        record:
          enabled: True
        snapshots:
          enabled: True
        detect:
          width: 3840
          height: 2160
        motion:
          mask:
            - 2596,188,3696,188,3696,80,2596,80
        zones:
          garage:
            coordinates: 3840,0,3840,2160,0,2160,0,0,2649,0,2565,561,3240,983,3571,0
      camera-garage-rear:
        ffmpeg:
          inputs:
            - path: rtsp://admin:${pw.camera}@camera-garage-rear.home.gustafson.me:554
              roles:
                - detect
                - audio
                - record
        record:
          enabled: True
        snapshots:
          enabled: True
        detect:
          width: 3840
          height: 2160
        motion:
          mask:
            - 2596,188,3696,188,3696,80,2596,80
            - 2569,0,3840,0,3840,979
        zones:
          garage_rear:
            coordinates: 2396,0,1279,0,600,176,1237,2160,2537,2160,3613,898
      camera-s-side:
        ffmpeg:
          inputs:
            - path: rtsp://admin:${pw.camera}@camera-s-side.home.gustafson.me:554
              roles:
                - detect
                - audio
                - record
        record:
          enabled: True
        snapshots:
          enabled: True
        detect:
          width: 3840
          height: 2160
        motion:
          mask:
            - 2596,188,3696,188,3696,80,2596,80
            - 3840,0,0,0,0,582,991,265,1953,166,2900,223,3413,323,3648,463,3840,754
        zones:
          s_side:
            coordinates: 0,2160,2298,2160,3262,1528,3633,1125,3012,253,1861,269,904,407,0,696
        objects:
          filters:
            car:
              mask:
                - 3840,0,0,0,0,582,991,265,1953,166,2900,223,3413,323,3648,463,3840,754
            person:
              mask:
                - 3840,0,0,0,0,582,991,265,1953,166,2900,223,3413,323,3648,463,3840,754
      camera-pool:
        ffmpeg:
          inputs:
            - path: rtsp://admin:${pw.camera}@camera-pool.home.gustafson.me:554
              roles:
                - detect
                - audio
                - record
        record:
          enabled: True
        snapshots:
          enabled: True
        detect:
          width: 3840
          height: 2160
        motion:
          mask:
            - 2596,188,3696,188,3696,80,2596,80
            - 3337,0,3840,0,3840,449
            - 166,0,0,0,0,136
      camera-back-yard:
        ffmpeg:
          inputs:
            - path: rtsp://admin:${pw.camera}@camera-back-yard.home.gustafson.me:554
              roles:
                - detect
                - audio
                - record
        record:
          enabled: True
        snapshots:
          enabled: True
        detect:
          width: 3840
          height: 2160
        motion:
          mask:
            - 2596,188,3696,188,3696,80,2596,80
            - 866,0,0,609,0,0
            - 2995,86,2608,0,3840,0,3840,730
        zones:
          patio:
            coordinates: 3124,2160,3036,1855,2651,1919,2430,1039,1975,1037,1807,874,1472,940,1219,884,987,1031,481,2160
          back_yard:
            coordinates: 822,1309,991,1011,1231,864,1811,864,1983,1033,2434,1031,2821,1121,3788,802,3042,156,1781,30,804,116,0,766,0,1185
        objects:
          filters:
            car:
              mask:
                - 866,0,0,609,0,0
                - 2995,86,2608,0,3840,0,3840,730
            person:
              mask:
                - 866,0,0,609,0,0
                - 2995,86,2608,0,3840,0,3840,730
      camera-patio:
        ffmpeg:
          inputs:
            - path: rtsp://admin:${pw.camera}@camera-patio.home.gustafson.me:554
              roles:
                - detect
                - audio
                - record
        record:
          enabled: True
        snapshots:
          enabled: True
        detect:
          width: 4096
          height: 1800
        motion:
          mask:
            - 3020,154,3950,154,3950,76,3020,76
            - 0,0,370,0,0,728
            - 3681,251,3870,68,4030,415,3853,623
        zones:
          patio:
            coordinates: 1375,0,2862,0,3126,617,3749,757,3964,1347,3415,1800,764,1800,377,1468,619,926,866,945
      doorbell-basement:
        ffmpeg:
          inputs:
            - path: rtsp://admin:${pw.doorbell}@doorbell-basement.home.gustafson.me:554
              roles:
                - detect
                - audio
                - record
        record:
          enabled: True
        snapshots:
          enabled: True
        detect:
          width: 2560
          height: 1920
        motion:
          mask:
            - 2560,52,2560,0,1970,0,1970,52
        zones:
          basement_patio:
            coordinates: 0,1920,2560,1920,2560,719,584,857,0,823
      camera-guest-patio:
        ffmpeg:
          inputs:
            - path: rtsp://admin:${pw.camera}@camera-guest-patio.home.gustafson.me:554
              roles:
                - detect
                - audio
                - record
        record:
          enabled: True
        snapshots:
          enabled: True
        detect:
          width: 3840
          height: 2160
        motion:
          mask:
            - 2596,188,3696,188,3696,80,2596,80
            - 3840,0,3453,0,3840,475
        zones:
          guest_patio:
            coordinates: 928,2160,229,1344,606,600,1035,160,2288,82,2859,251,3449,620,3631,985,3840,1646,3840,2160
      camera-n-side:
        ffmpeg:
          inputs:
            - path: rtsp://admin:${pw.camera}@camera-n-side.home.gustafson.me:554
              roles:
                - detect
                - audio
                - record
        record:
          enabled: True
        snapshots:
          enabled: True
        detect:
          width: 3840
          height: 2160
        motion:
          mask:
            - 2596,188,3696,188,3696,80,2596,80
            - 3369,0,3840,0,3840,285
            - 331,0,0,0,0,287
            - 1737,2160,1883,2160,2085,1779,1650,1574,1362,1935
            - 2055,1153,2342,1283,2208,1530,1895,1400
        zones:
          n_side:
            coordinates: 0,826,453,1444,1263,2160,2731,2160,3090,1500,3840,1785,3840,758,2134,0,592,0,0,555
        objects:
          filters:
            car:
              mask:
                - 3369,0,3840,0,3840,285
                - 331,0,0,0,0,287
            person:
              mask:
                - 3369,0,3840,0,3840,285
                - 331,0,0,0,0,287
    go2rtc:
      streams:
        doorbell-front:
          - rtsp://admin:${pw.doorbell}@doorbell-front.home.gustafson.me:554/cam/realmonitor?channel=1&subtype=0
        doorbell-basement:
          - rtsp://admin:${pw.doorbell}@doorbell-basement.home.gustafson.me:554/cam/realmonitor?channel=1&subtype=0
        camera-driveway:
          - rtsp://admin:${pw.camera}@camera-driveway.home.gustafson.me:554/cam/realmonitor?channel=1&subtype=0
        camera-garage-n:
          - rtsp://admin:${pw.camera}@camera-garage-n.home.gustafson.me:554/cam/realmonitor?channel=1&subtype=0
        camera-garage-s:
          - rtsp://admin:${pw.camera}@camera-garage-s.home.gustafson.me:554/cam/realmonitor?channel=1&subtype=0
        camera-garage-rear:
          - rtsp://admin:${pw.camera}@camera-garage-rear.home.gustafson.me:554/cam/realmonitor?channel=1&subtype=0
        camera-guest-patio:
          - rtsp://admin:${pw.camera}@camera-guest-patio.home.gustafson.me:554/cam/realmonitor?channel=1&subtype=0
        camera-n-side:
          - rtsp://admin:${pw.camera}@camera-n-side.home.gustafson.me:554/cam/realmonitor?channel=1&subtype=0
        camera-s-side:
          - rtsp://admin:${pw.camera}@camera-s-side.home.gustafson.me:554/cam/realmonitor?channel=1&subtype=0
        camera-patio:
          - rtsp://admin:${pw.camera}@camera-patio.home.gustafson.me:554/cam/realmonitor?channel=1&subtype=0
        camera-pool:
          - rtsp://admin:${pw.camera}@camera-pool.home.gustafson.me:554/cam/realmonitor?channel=1&subtype=0
        camera-porch-n:
          - rtsp://admin:${pw.camera}@camera-porch-n.home.gustafson.me:554/cam/realmonitor?channel=1&subtype=0
        camera-porch-s:
          - rtsp://admin:${pw.camera}@camera-porch-s.home.gustafson.me:554/cam/realmonitor?channel=1&subtype=0
        camera-back-yard:
          - rtsp://admin:${pw.camera}@camera-back-yard.home.gustafson.me:554/cam/realmonitor?channel=1&subtype=0
  '';
in
{
  imports = [(homelabService {
    name = "frigate";
    requires = [ "nas.mount" ];
    docker = {
      image = "ghcr.io/blakeblackshear/frigate:stable";
      environment = {
        FRIGATE_RTSP_PASSWORD = "password";
      };
      ports = [
        "5000"
        "1935"
        "1984" # go2rtc API
        "8554" # go2rtc RTSP
        "8555" # go2rtc WebRTC
        "8555/udp"
      ];
      configVolume = "/config";
      volumes = [
        "${configFile}:/config/config.yml:ro"
        "/d/frigate/media:/media/frigate"
        "/etc/localtime:/etc/localtime:ro"
      ];
      extraOptions = [
        "--shm-size=16g"
        "--gpus=all"
        "--device=/dev/apex_0:/dev/apex_0"
        "--device=/dev/apex_1:/dev/apex_1"
        "--privileged"
      ];
    };
    extraConfig = {
      boot.extraModulePackages = with config.boot.kernelPackages; [ gasket ];

      services.udev.extraRules = ''
        SUBSYSTEM=="usb",ATTRS{idVendor}=="1a6e",ATTRS{idProduct}=="089a",GROUP="plugdev"
        SUBSYSTEM=="usb",ATTRS{idVendor}=="18d1",ATTRS{idProduct}=="9302",GROUP="plugdev"
      '';
    };
  })];
}
