let
  user = "josh";
  group = "users";
in
{ ... }:
{
  inherit user group;
  container = {
    pullImage = import ../images/esphome.nix;
    environment = {
      PLATFORMIO_CORE_DIR = "/cache/.plattformio";
      PLATFORMIO_GLOBALLIB_DIR = "/cache/.plattformioLibs";
    };
    ports = [
      "6052"
    ];
    configVolume = "/config";
    extraOptions = [
      "--tmpfs=/.cache:exec,mode=1777"
      "--tmpfs=/.local:exec,mode=1777"
      "--tmpfs=/cache:exec,mode=1777"
      "--tmpfs=/config/.esphome/build:exec,mode=1777"
      "--tmpfs=/config/.esphome/external_components:exec,mode=1777"
    ];
  };
}
