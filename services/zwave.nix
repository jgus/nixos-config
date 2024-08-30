{ config, ... }:
let
  zwave-area = area: (
    let
      device = "/dev/serial/by-id/usb-Zooz_800_Z-Wave_Stick_533D004242-if00";
    in
    {
      name = "zwave-${area}";
      docker = {
        image = "zwavejs/zwave-js-ui";
        environment = {
          TZ = config.time.timeZone;
        };
        ports = [
          "8091"
          "3000"
        ];
        configVolume = "/usr/src/app/store";
        extraOptions = [
          "--device=${device}:/dev/zwave"
        ];
      };
    }
  );
in
map zwave-area [ "basement" "main" "upstairs" ]
