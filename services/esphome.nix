let
  user = "josh";
  group = "users";
in
{ config, ... }:
{
  name = "esphome";
  inherit user group;
  docker = {
    image = "ghcr.io/esphome/esphome";
    environment = {
      PLATFORMIO_CORE_DIR = "/cache/.plattformio";
      PLATFORMIO_GLOBALLIB_DIR = "/cache/.plattformioLibs";
    };
    ports = [
      "6052"
    ];
    configVolume = "/config";
    extraOptions =
      let
        uid = toString config.users.users.${user}.uid;
        gid = toString config.users.groups.${group}.gid;
      in
      [
        "--tmpfs=/cache:exec,uid=${uid},gid=${gid}"
        "--tmpfs=/.cache:exec,uid=${uid},gid=${gid}"
        "--tmpfs=/config/.esphome/build:exec,uid=${uid},gid=${gid}"
        "--tmpfs=/config/.esphome/external_components:exec,uid=${uid},gid=${gid}"
      ];
  };
}
