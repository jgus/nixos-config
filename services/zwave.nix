{ config, ... }:
let
  zwave-area = area: (
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
      };
    }
  );
in
map zwave-area [ "basement" "main" "upstairs" ]
