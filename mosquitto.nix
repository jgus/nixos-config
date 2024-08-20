{ config, pkgs, ... }:

with builtins;
with (import ./functions.nix) { inherit pkgs; };
let
  service = "mosquitto";
  serviceMount = "var-lib-${builtins.replaceStrings ["-"] ["\\x2d"] service}.mount";
  image = "eclipse-mosquitto";
  pw = import ./.secrets/passwords.nix;
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
  passwordFileDer = pkgs.runCommand "passwordFileDer" {} (concatStringsSep "\n" (
    [
      "mkdir \${out}"
      "touch \${out}/password.conf"
      "chmod 600 \${out}/password.conf"
      # "chown 1883:1883 \${out}/password.conf"
    ] ++
    (map (n: "${pkgs.mosquitto}/bin/mosquitto_passwd -b \${out}/password.conf ${n} ${getAttr n pw.mqtt}\n") (attrNames pw.mqtt)) ++
    [ "" ]
  ));
  aclFile = pkgs.writeText "acl.conf" ''
    user ha
    topic readwrite #
    user frigate
    topic readwrite #
    user zigbee2mqtt
    topic readwrite #
    user theater_remote
    topic readwrite #
    user frodo
    topic readwrite valetudo/Frodo/#
    user sam
    topic readwrite valetudo/Sam/#
    user merry
    topic readwrite valetudo/Merry/#
    user pippin
    topic readwrite valetudo/Pippin/#
  '';
  configFile = pkgs.writeText "mosquitto.conf" ''
    listener 1883
    persistence true
    persistence_location /mosquitto/data/
    log_dest stdout
    acl_file /mosquitto/config/acl_file.conf
    password_file /mosquitto/config/password_file.conf
  '';
in
if (machine.hostName != addresses.records."${service}".host) then {} else
{
  imports = [
    ./docker.nix
    (docker-services {
      name = service;
      image = image;
      requires = [ serviceMount ];
    })
  ];

  virtualisation.oci-containers.containers."${service}" = {
    image = image;
    autoStart = true;
    extraOptions = (addresses.dockerOptions service) ++ [
      "--read-only"
    ];
    ports = [
      "1883"
      "9001"
    ];
    volumes = [
      "${passwordFileDer}/password.conf:/mosquitto/config/password_file.conf:ro"
      "${aclFile}:/mosquitto/config/acl_file.conf:ro"
      "${configFile}:/mosquitto/config/mosquitto.conf:ro"
      "/var/lib/${service}:/mosquitto/data"
    ];
  };

  fileSystems."/var/lib/${service}" = {
    device = "localhost:/varlib-${service}";
    fsType = "glusterfs";
  };
}
