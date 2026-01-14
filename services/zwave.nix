{ config, ... }:
let
  zwave-area = area: {
    name = "zwave-${area}";
    container = {
      readOnly = false;
      pullImage = import ../images/zwave-js-ui.nix;
      environment = {
        TZ = config.time.timeZone;
      };
      ports = [
        "8091"
        "3000"
      ];
      configVolume = "/usr/src/app/store";
    };
  };
in
map zwave-area [ "basement" "main" "north" "upstairs" ]
