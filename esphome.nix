{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  service = "esphome";
  serviceMount = "var-lib-${builtins.replaceStrings ["-"] ["\\x2d"] service}.mount";
  image = "ghcr.io/esphome/esphome";
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
in
if (machine.hostName != addresses.records."${service}".host) then {} else
{
  imports = [ ./docker.nix ];

  virtualisation.oci-containers.containers."${service}" = {
    image = image;
    autoStart = true;
    user = "${toString config.users.users.josh.uid}:${toString config.users.groups.users.gid}";
    extraOptions = (addresses.dockerOptions service) ++ [
      "--tmpfs=/cache:exec,uid=${toString config.users.users.josh.uid},gid=${toString config.users.groups.users.gid}"
      "--tmpfs=/.cache/pip:exec,uid=${toString config.users.users.josh.uid},gid=${toString config.users.groups.users.gid}"
      "--tmpfs=/config/.esphome/build:exec,uid=${toString config.users.users.josh.uid},gid=${toString config.users.groups.users.gid}"
      "--tmpfs=/config/.esphome/external_components:exec,uid=${toString config.users.users.josh.uid},gid=${toString config.users.groups.users.gid}"
    ];
    environment = {
      PLATFORMIO_CORE_DIR = "/cache/.plattformio";
      PLATFORMIO_GLOBALLIB_DIR = "/cache/.plattformioLibs";
    };
    ports = [
      "6052"
    ];
    volumes = [
      "/var/lib/${service}:/config"
    ];
  };

  fileSystems."/var/lib/${service}" = {
    device = "localhost:/varlib-${service}";
    fsType = "glusterfs";
  };

  systemd = {
    services = docker-services {
      name = service;
      image = image;
      requires = [ serviceMount ];
    };
  };
}
