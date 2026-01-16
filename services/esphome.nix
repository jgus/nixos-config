let
  user = "josh";
  group = "users";
in
{ ... }:
{
  inherit user group;
  container = {
    readOnly = false;
    pullImage = import ../images/esphome.nix;
    environment = {
      PLATFORMIO_CORE_DIR = "/cache/.plattformio";
      PLATFORMIO_GLOBALLIB_DIR = "/cache/.plattformioLibs";
    };
    ports = [
      "6052"
    ];
    configVolume = "/config";
    tmpFs = [
      "/.cache:exec,mode=0777"
      "/.local:exec,mode=0777"
      "/cache:exec,mode=0777"
      "/config/.esphome/build:exec,mode=0777"
      "/config/.esphome/external_components:exec,mode=0777"
    ];
  };
}
