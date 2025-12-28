let
  user = "josh";
  group = "users";
in
{ config, pkgs, ... }:
{
  inherit user group;
  docker = {
    pullImage =
      # nix-shell -p nix-prefetch-docker --run 'nix-prefetch-docker --quiet --image-name ghcr.io/esphome/esphome --image-tag latest'
      {
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
    extraOptions =
      let
        uid = toString config.users.users.${user}.uid;
        gid = toString config.users.groups.${group}.gid;
      in
      [
        "--tmpfs=/.cache:exec,uid=${uid},gid=${gid}"
        "--tmpfs=/.local:exec,uid=${uid},gid=${gid}"
        "--tmpfs=/cache:exec,uid=${uid},gid=${gid}"
        "--tmpfs=/config/.esphome/build:exec,uid=${uid},gid=${gid}"
        "--tmpfs=/config/.esphome/external_components:exec,uid=${uid},gid=${gid}"
      ];
  };
}
