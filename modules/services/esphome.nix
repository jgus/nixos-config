let
  user = "josh";
  group = "users";
in
{ ... }:
{
  homelab.services.esphome = {
    inherit user group;
    container = {
      pullImage = import ../../images/esphome.nix;
      capabilities = {
        NET_RAW = true;
      };
      environment = {
        PLATFORMIO_CORE_DIR = "/cache/.plattformio";
        PLATFORMIO_GLOBALLIB_DIR = "/cache/.plattformioLibs";
      };
      configVolume = "/config";
      tmpFs = [
        "/.cache:exec,mode=0777"
        "/.local:exec,mode=0777"
        "/cache:exec,mode=0777"
        "/config/.esphome/build:exec,mode=0777"
        "/config/.esphome/external_components:exec,mode=0777"
      ];
      ports = [
        "6052"
      ];
    };
  };
}
