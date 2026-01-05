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
      "/.cache"
      "/.local"
      "/cache"
      "/config/.esphome/build"
      "/config/.esphome/external_components"
    ];
  };
}
