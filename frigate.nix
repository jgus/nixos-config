{ config, pkgs, ... }:

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
      mqtt:
        host: mqtt
        user: frigate
        password: CWPRbirZT2zAhtW3kUyt
      record:
        retain:
          days: 365
          mode: motion
      ffmpeg:
        hwaccel_args: -hwaccel cuda
        output_args:
          record: -f segment -segment_time 10 -segment_format mp4 -reset_timestamps 1 -strftime 1 -c copy
      cameras:
        front-doorbell:
          ffmpeg:
            inputs:
              - path: rtsp://admin:T8EgVFbyiMXGDJhZFkVb@front-doorbell.home.gustafson.me:554
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
              - 1972,0,2560,0,2560,56,1972,56
          zones:
            yard:
              coordinates: 2560,1920,0,1920,0,1086,901,1106,1228,1101,1296,1192,1865,1288,2560,1200
            porch:
              coordinates: 1221,1634,1963,1688,2119,1920,0,1920,678,1532
      objects:
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
      go2rtc:
        streams:
          front-doorbell:
            # - rtsp://admin:T8EgVFbyiMXGDJhZFkVb@front-doorbell.home.gustafson.me:554/cam/realmonitor?channel=1&subtype=0#backchannel=0
            - rtsp://admin:T8EgVFbyiMXGDJhZFkVb@front-doorbell.home.gustafson.me:554/cam/realmonitor?channel=1&subtype=0
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
