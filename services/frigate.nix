with builtins;
let
  pw = import ./../.secrets/passwords.nix;
  detector = "coral";
  # detector = "onnx";
  doorbell = {
    user = "admin";
    password = pw.doorbell;
    width = 2560;
    height = 1920;
    detectStream = 0;
    masks = [ [ 1 0.027 1 0 0.77 0 0.77 0.027 ] ];
  };
  amcrestIP8M = {
    user = "admin";
    password = pw.camera;
    width = 3840;
    height = 2160;
    detectStream = 2;
    masks = [ [ 0.676 0.087 0.963 0.087 0.963 0.037 0.676 0.037 ] ];
  };
  empireTechT180 = {
    user = "admin";
    password = pw.camera;
    width = 4096;
    height = 1800;
    detectStream = 2;
    masks = [ [ 0.737 0.087 0.964 0.087 0.964 0.042 0.737 0.042 ] ];
  };
  cameras = {
    doorbell-front = doorbell // {
      masks = doorbell.masks ++ [
        [ 0.298 0.118 1 0.334 1 0.458 0.936 0.461 0.834 0.551 0.554 0.583 0.283 0.59 ]
      ];
      zones = {
        porch = [ 0 1 0 0.759 0.336 0.763 0.406 0.695 0.71 0.672 0.889 0.667 1 0.606 1 1 ];
        front_yard = [ 1 0.479 0.948 0.473 0.866 0.545 0.724 0.561 0.528 0.579 0.288 0.583 0.299 0.748 0.332 0.748 0.327 0.679 0.615 0.668 0.779 0.651 0.931 0.628 1 0.595 ];
      };
    };
    camera-porch-n = amcrestIP8M // {
      masks = amcrestIP8M.masks ++ [
        [ 0.907 0 1 0 1 0.104 ]
        [ 0.256 0 0.079 0 0.097 0.096 ]
      ];
      zones = {
        porch = [ 0.149 0.84 0 0.566 0 0.145 0.076 0.033 0.143 0.274 0.245 0.558 ];
        front_yard = [ 0.274 1 1 1 1 0 0.256 0 0.141 0.067 0.105 0.109 0.231 0.517 0.291 0.581 0.186 0.879 ];
      };
    };
    camera-porch-s = amcrestIP8M // {
      masks = amcrestIP8M.masks ++ [
        [ 0.215 0 0.064 0 0.104 0.131 ]
      ];
      zones = {
        porch = [ 0.422 0 1 0 1 1 0.215 1 0.534 0.326 0.435 0.248 ];
        front_yard = [ 0.173 0.387 0.09 0 0.414 0 0.421 0.217 0.407 0.312 0.496 0.381 0.317 0.769 ];
      };
    };
    camera-driveway = amcrestIP8M // {
      masks = amcrestIP8M.masks ++ [
        [ 1 0 1 0.405 0.759 0.194 0.512 0.062 0.325 0.114 0.12 0.23 0.104 0 ]
        [ 0.755 0.294 0.853 0.374 0.841 0.276 0.808 0.245 ]
      ];
      zones = {
        front_yard = [ 0.906 0.318 0.809 0.231 0.734 0.302 0.757 0.418 0.859 0.547 ];
        driveway = [ 0.746 1 0.863 0.553 0.757 0.422 0.732 0.301 0.808 0.231 0.573 0.087 0.425 0.089 0.13 0.233 0.201 0.66 0.152 0.705 0.252 1 ];
      };
    };
    camera-garage-n = amcrestIP8M // {
      zones = {
        garage = [ 0 1 1 1 1 0.472 0.597 0.012 0.583 0.253 0.212 0.426 0.152 0.327 0 0.421 ];
      };
    };
    camera-garage-s = amcrestIP8M // {
      zones = {
        garage = [ 1 0 1 1 0 1 0 0 0.437 0.029 0.668 0.259 0.844 0.455 0.93 0 ];
      };
    };
    camera-garage-rear = amcrestIP8M // {
      masks = amcrestIP8M.masks ++ [
        [ 0.669 0 1 0 1 0.453 ]
      ];
      zones = {
        garage_rear = [ 0.624 0 0.333 0 0.156 0.081 0.322 1 0.66 1 0.941 0.416 ];
      };
    };
    camera-s-side = amcrestIP8M // {
      masks = amcrestIP8M.masks ++ [
        [ 1 0 0 0 0 0.269 0.258 0.122 0.508 0.077 0.755 0.103 0.889 0.149 0.95 0.214 1 0.349 ]
      ];
      zones = {
        s_side = [ 0 1 1 1 1 1 1 1 1 0.473 0.875 0.157 0.729 0.114 0.511 0.099 0.262 0.139 0 0.302 ];
      };
    };
    camera-pool = amcrestIP8M // {
      masks = amcrestIP8M.masks ++ [
        [ 0.869 0 1 0 1 0.207 ]
        [ 0.043 0 0 0 0 0.063 ]
      ];
      zones = {
        back_yard = [ 0 1 0 0 1 0 1 1 ];
      };
    };
    camera-back-yard = amcrestIP8M // {
      masks = amcrestIP8M.masks ++ [
        [ 0.226 0 0 0.281 0 0 ]
        [ 0.78 0.04 0.679 0 1 0 1 0.338 ]
      ];
      zones = {
        patio = [ 0.814 1 0.791 0.858 0.69 0.888 0.633 0.481 0.514 0.48 0.47 0.405 0.383 0.435 0.317 0.409 0.257 0.477 0.125 1 ];
        back_yard = [ 0.214 0.606 0.258 0.468 0.32 0.4 0.471 0.4 0.516 0.478 0.634 0.477 0.734 0.519 0.986 0.371 0.792 0.072 0.464 0.014 0.209 0.054 0 0.355 0 0.548 ];
      };
    };
    camera-patio = empireTechT180 // {
      masks = empireTechT180.masks ++ [
        [ 0 0 0.09 0 0 0.41 ]
        [ 0.898 0.141 0.945 0.037 0.984 0.233 0.941 0.351 ]
      ];
      zones = {
        patio = [ 0.335 0 0.698 0 0.763 0.347 0.915 0.425 0.968 0.758 0.833 1 0.186 1 0.092 0.827 0.151 0.522 0.211 0.531 ];
      };
    };
    doorbell-basement = doorbell // {
      zones = {
        basement_patio = [ 1 1 1 0.037 0.841 0.388 0.716 0.404 0.246 0.434 0 0.415 0 1 0.275 1 ];
      };
    };
    camera-guest-patio = amcrestIP8M // {
      masks = amcrestIP8M.masks ++ [
        [ 1 0 0.899 0 1 0.219 ]
      ];
      zones = {
        basement_patio = [ 0.242 1 0.059 0.622 0.158 0.278 0.269 0.074 0.596 0.038 0.744 0.116 0.898 0.287 0.945 0.456 1 0.762 1 1 ];
      };
    };
    camera-n-side = amcrestIP8M // {
      masks = amcrestIP8M.masks ++ [
        [ 0.877 0 1 0 1 0.131 ]
        [ 0.086 0 0 0 0 0.132 ]
        [ 0.452 1 0.49 1 0.543 0.823 0.43 0.729 0.355 0.895 ]
        [ 0.535 0.533 0.61 0.594 0.575 0.708 0.493 0.648 ]
      ];
      zones = {
        n_side = [ 0 0.382 0.118 0.669 0.329 1 0.711 1 0.805 0.694 1 0.826 1 0.351 0.556 0 0.154 0 0 0.256 ];
      };
    };
  };
  zone_objects = {
    back_yard = [ "person" "face" ];
    basement_patio = [ "person" "face" ];
    driveway = [ "person" "face" "car" "license_plate" "amazon" "usps" "ups" "fedex" "package" ];
    front_yard = [ "person" "face" "car" "license_plate" "amazon" "usps" "ups" "fedex" "package" ];
    garage = [ "person" "face" "car" ];
    garage_rear = [ "person" "face" ];
    n_side = [ "person" "face" ];
    patio = [ "person" "face" ];
    porch = [ "person" "face" "car" "license_plate" "amazon" "usps" "ups" "fedex" "package" ];
    s_side = [ "person" "face" "car" "license_plate" "amazon" "usps" "ups" "fedex" "package" ];
  };
  configuration = {
    version = "0.16-0";
    # logger.default = "debug";
    mqtt = {
      host = "mqtt.home.gustafson.me";
      user = "frigate";
      password = pw.mqtt.frigate;
    };
    objects = {
      track = [ "person" "face" "car" "license_plate" "amazon" "usps" "ups" "fedex" "package" ];
      filters.person = {
        min_score = 0.5;
        threshold = 0.8;
      };
    };
    audio.enabled = true;
    detectors = (if (detector == "coral") then {
      coral1 = { type = "edgetpu"; device = "pci:0"; };
      coral2 = { type = "edgetpu"; device = "pci:1"; };
      # coral3 = { type = "edgetpu"; device = "usb:0"; };
      # coral4 = { type = "edgetpu"; device = "usb:1"; };
    } else if (detector == "onnx") then {
      onnx0 = { type = "onnx"; device = "0"; };
      onnx1 = { type = "onnx"; device = "1"; };
    } else { });
    model = (if (detector == "coral") then {
      path = "plus://d5ceaa014cdcd47352e8cfc6ab0326fa"; # custom 10/18/2025
    } else if (detector == "onnx") then {
      # path = "plus://717c77b1c548a9f5371b44e1ec8466fd"; # stock 2025.2
      path = "plus://e6a3aa40b94b1494f5beac6f427343cb"; # custom 8/13/2025
    } else { });
    detect = {
      enabled = true;
    };
    record = {
      enabled = true;
      retain = { days = 7; mode = "motion"; };
      alerts.retain = { days = 60; mode = "active_objects"; };
      detections.retain = { days = 60; mode = "active_objects"; };
    };
    ffmpeg = {
      hwaccel_args = "preset-nvidia";
      output_args.record = "preset-record-generic-audio-copy";
    };
    birdseye = {
      enabled = true;
      mode = "objects";
      width = 3840;
      height = 2160;
      restream = true;
    };
    semantic_search = {
      enabled = true;
      model = "jinav1";
      model_size = "large";
    };
    face_recognition = {
      enabled = true;
      model_size = "large";
    };
    lpr = {
      enabled = true;
      device = "GPU";
      model_size = "small";
    };
    cameras = mapAttrs
      (key: value:
        let
          numlist = (list: concatStringsSep "," (map toString list));
          masks = map numlist value.masks;
        in
        {
          ffmpeg.inputs =
            if (value.detectStream == 0) then
              [
                {
                  path = "rtsp://${value.user}:${value.password}@${key}.home.gustafson.me:554/cam/realmonitor?channel=1&subtype=0";
                  roles = [ "detect" "audio" "record" ];
                }
              ]
            else
              [
                {
                  path = "rtsp://${value.user}:${value.password}@${key}.home.gustafson.me:554/cam/realmonitor?channel=1&subtype=${toString value.detectStream}";
                  roles = [ "detect" "audio" ];
                }
                {
                  path = "rtsp://${value.user}:${value.password}@${key}.home.gustafson.me:554/cam/realmonitor?channel=1&subtype=0";
                  roles = [ "record" ];
                }
              ];
          record.enabled = true;
          snapshots.enabled = true;
          motion.mask = masks;
        } // (if (value ? zones) then {
          zones = mapAttrs
            (key: value:
              {
                coordinates = numlist value;
                objects = (getAttr key zone_objects);
              }
            )
            value.zones;
        } else { }) // (if (value ? masks) then {
          objects.filters = {
            car.mask = masks;
            person.mask = masks;
          };
        } else { })
      )
      cameras;
    go2rtc.streams = mapAttrs
      (key: value: [ "rtsp://${value.user}:${value.password}@${key}.home.gustafson.me:554/cam/realmonitor?channel=1&subtype=2" ])
      cameras;
  };
in
{ config, pkgs, ... }:
{
  requires = [ "storage-frigate.mount" "zfs-import-f.service" ];
  docker = {
    image = "ghcr.io/blakeblackshear/frigate:stable-tensorrt";
    environment = {
      PLUS_API_KEY = pw.frigate_plus;
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
      "${(pkgs.formats.yaml { }).generate "config.yml" configuration}:/config/config.yml:ro"
      "/storage/frigate/media:/media/frigate"
      "/etc/localtime:/etc/localtime:ro"
    ];
    extraOptions = [
      "--shm-size=4g"
      "--tmpfs=/tmp"
      "--ulimit=nofile=${toString (4*1024)}:${toString (16*1024)}"
      "--device=nvidia.com/gpu=all"
      "--device=/dev/apex_0:/dev/apex_0"
      "--device=/dev/apex_1:/dev/apex_1"
      "--device=/dev/bus/usb/006/004:/dev/bus/usb/006/004"
      "--device=/dev/bus/usb/006/005:/dev/bus/usb/006/005"
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
}
