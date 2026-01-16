{ config, ... }:
let
  zwave-area = area: {
    name = "zwave-${area}";
    container = {
      pullImage = import ../images/zwave-js-ui.nix;
      environment = {
        TZ = config.time.timeZone;
      };
      ports = [
        "8091"
        "3000"
      ];
      configVolume = "/usr/src/app/store";
      environment = {
        TRUST_PROXY = "true";
      };
    };
  };
in
map zwave-area [ "basement" "main" "north" "upstairs" ]
