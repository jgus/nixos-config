let
  user = "josh";
  group = "users";
in
{ ... }:
{
  inherit user group;
  container = {
    pullImage = {
      imageName = "ghcr.io/esphome/esphome";
      imageDigest = "sha256:84d986f14c0e2807f6b572b367411bbdc6ed456f2350a1d00ea109233558d545";
      hash = "sha256-wIWa+1Z4jsaInVdJAoSSdLooQRSy5Mnlv6KR/aYtty4=";
      finalImageName = "ghcr.io/esphome/esphome";
      finalImageTag = "latest";
    };
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
