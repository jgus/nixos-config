{ lib, ... }:
let
  zwave-area = area: {
    "zwave-${area}" = {
      container = {
        pullImage = import ../../images/zwave-js-ui.nix;
        environment = {
          TRUST_PROXY = "true";
        };
        configVolume = "/usr/src/app/store";
        ports = [
          "8091"
          "3000"
        ];
      };
    };
  };
in
{
  homelab.services = lib.homelab.recursiveUpdates (map zwave-area [ "basement" "main" "north" "upstairs" ]);
}

