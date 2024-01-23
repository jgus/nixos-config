{ config, pkgs, ... }:

let pw = import ./.secrets/passwords.nix;
in
{
  imports = [ ./docker.nix ];

  services.udev.extraRules = ''
    SUBSYSTEM=="usb",ATTRS{idVendor}=="1a6e",ATTRS{idProduct}=="089a",GROUP="plugdev"
    SUBSYSTEM=="usb",ATTRS{idVendor}=="18d1",ATTRS{idProduct}=="9302",GROUP="plugdev"
  '';

  system.activationScripts = {
    frigateSetup.text = ''
      ${pkgs.zfs}/bin/zfs list d/varlib/frigate >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create d/varlib/frigate
    '';
  };

  networking.firewall.allowedTCPPorts = [ 5000 1935 ];

  environment.etc = {
    "frigate/config.yml".text = ''
      # logger:
      #   default: debug
      mqtt:
        host: mqtt.home.gustafson.me
        user: frigate
        password: ${pw.mqtt.frigate}
      objects:
        track:
          - person
          # - car
        filters:
          person:
            min_score: 0.5
            threshold: 0.8
      detectors:
        coral1:
          type: edgetpu
          device: usb:0
        coral2:
          type: edgetpu
          device: usb:1
      record:
        retain:
          days: 365
          mode: motion
      ffmpeg:
        hwaccel_args: preset-nvidia-h264
        output_args:
          record: -f segment -segment_time 10 -segment_format mp4 -reset_timestamps 1 -strftime 1 -c copy
      birdseye:
        enabled: True
        mode: objects
        restream: True
      cameras:
        doorbell-front:
          ffmpeg:
            inputs:
              - path: rtsp://admin:${pw.doorbell}@doorbell-front.home.gustafson.me:554
                roles:
                  - detect
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
        doorbell-basement:
          ffmpeg:
            inputs:
              - path: rtsp://admin:${pw.doorbell}@doorbell-basement.home.gustafson.me:554
                roles:
                  - detect
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
        camera-driveway:
          ffmpeg:
            inputs:
              - path: rtsp://admin:${pw.camera}@camera-driveway.home.gustafson.me:554
                roles:
                  - detect
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
              - 3840,0,3840,783,2961,347,1971,35,604,339,569,0
        camera-garage-n:
          ffmpeg:
            inputs:
              - path: rtsp://admin:${pw.camera}@camera-garage-n.home.gustafson.me:554
                roles:
                  - detect
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
        camera-garage-s:
          ffmpeg:
            inputs:
              - path: rtsp://admin:${pw.camera}@camera-garage-s.home.gustafson.me:554
                roles:
                  - detect
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
        camera-garage-rear:
          ffmpeg:
            inputs:
              - path: rtsp://admin:${pw.camera}@camera-garage-rear.home.gustafson.me:554
                roles:
                  - detect
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
        camera-guest-patio:
          ffmpeg:
            inputs:
              - path: rtsp://admin:${pw.camera}@camera-guest-patio.home.gustafson.me:554
                roles:
                  - detect
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
        camera-n-side:
          ffmpeg:
            inputs:
              - path: rtsp://admin:${pw.camera}@camera-n-side.home.gustafson.me:554
                roles:
                  - detect
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
              - 3202,370,2022,144,1200,132,1048,273,553,475,452,0,3840,0,3840,639
        camera-s-side:
          ffmpeg:
            inputs:
              - path: rtsp://admin:${pw.camera}@camera-s-side.home.gustafson.me:554
                roles:
                  - detect
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
              - 2859,0,0,0,0,1983,1905,499,2770,612
        camera-patio:
          ffmpeg:
            inputs:
              - path: rtsp://admin:${pw.camera}@camera-patio.home.gustafson.me:554
                roles:
                  - detect
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
        camera-pool:
          ffmpeg:
            inputs:
              - path: rtsp://admin:${pw.camera}@camera-pool.home.gustafson.me:554
                roles:
                  - detect
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
        camera-porch-n:
          ffmpeg:
            inputs:
              - path: rtsp://admin:${pw.camera}@camera-porch-n.home.gustafson.me:554
                roles:
                  - detect
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
              - 3062,409,2267,152,1547,0,3840,0,3840,803
        camera-porch-s:
          ffmpeg:
            inputs:
              - path: rtsp://admin:${pw.camera}@camera-porch-s.home.gustafson.me:554
                roles:
                  - detect
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
    '';
  };

  systemd = {
    services = {
      frigate = {
        enable = true;
        description = "Frigate NVR";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = with pkgs; [ docker wget ];
        # 1984 - go2rtc API
        # 8554 - go2rtc RTSP
        # 8555 - go2rtc WebRTC
        script = ''
          docker container stop frigate >/dev/null 2>&1 || true ; \
          docker container rm -f frigate >/dev/null 2>&1 || true ; \
          docker run --rm --name frigate \
            --shm-size=1024m \
            --gpus all \
            --privileged \
            -v /dev/bus/usb/004:/dev/bus/usb/004 \
            -v /var/lib/frigate:/media/frigate \
            -v /etc/frigate/config.yml:/config/config.yml:ro \
            -v /etc/localtime:/etc/localtime:ro \
            -e FRIGATE_RTSP_PASSWORD='password' \
            -p 5000:5000 \
            -p 1935:1935 \
            -p 1984:1984 \
            -p 8554:8554 \
            -p 8555:8555 \
            -p 8555:8555/udp \
            ghcr.io/blakeblackshear/frigate:stable
        '';
        serviceConfig = {
          Restart = "on-failure";
        };
      };
      frigate-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull ghcr.io/blakeblackshear/frigate:stable | grep "Status: Downloaded"
          then
            systemctl restart frigate
          fi
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        startAt = "hourly";
      };
    };
  };
}
