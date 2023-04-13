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
        user: mqtt
        password: CWPRbirZT2zAhtW3kUyt
      record:
        retain:
          days: 365
          mode: motion
      ffmpeg:
        output_args:
          record: -f segment -segment_time 10 -segment_format mp4 -reset_timestamps 1 -strftime 1 -c copy
      cameras:
        cam1: # <------ Name the camera
          ffmpeg:
            inputs:
              - path: rtsp://viewer:sV7yekLozuvDGD8XP9fE@cam1:554/cam/realmonitor?channel=1&subtype=0
                roles:
                  - record
            inputs:
              - path: rtsp://viewer:sV7yekLozuvDGD8XP9fE@cam1:554/cam/realmonitor?channel=1&subtype=2
                roles:
                  - detect
          record:
            enabled: True
          snapshots:
            enabled: True
          detect:
            width: 1920
            height: 1080
          motion:
            mask:
              - 1392,0,1920,0,1920,48,1392,48
      detectors:
        coral1:
          type: edgetpu
          device: usb:0
        coral2:
          type: edgetpu
          device: usb:1
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
        script = ''
          docker container stop frigate >/dev/null 2>&1 || true ; \
          docker run --rm --name frigate \
            --shm-size=1024m \
            --privileged \
            -v /dev/bus/usb/004:/dev/bus/usb/004 \
            -v /var/lib/frigate:/media/frigate \
            -v /etc/frigate/config.yml:/config/config.yml:ro \
            -v /etc/localtime:/etc/localtime:ro \
            -e FRIGATE_RTSP_PASSWORD='password' \
            -p 5000:5000 \
            -p 1935:1935 \
            blakeblackshear/frigate:stable
          '';
        serviceConfig = {
          Restart = "on-failure";
        };
      };
      frigate-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull blakeblackshear/frigate:stable | grep "Status: Downloaded"
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
