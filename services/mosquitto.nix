{ config, pkgs, ... }:
let
  aclFile = pkgs.writeText "acl.conf" ''
    user ha
    topic readwrite #
    user server
    topic readwrite server/#
    topic readwrite systemctl/#
    topic readwrite homeassistant/#
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
{
  container = {
    pullImage = import ../images/mosquitto.nix;
    configVolume = "/mosquitto/data";
    ports = [
      "1883"
      "9001"
    ];
    volumes = [
      "${config.sops.secrets."mqtt/file".path}:/mosquitto/config/password_file.conf:ro"
      "${aclFile}:/mosquitto/config/acl_file.conf:ro"
      "${configFile}:/mosquitto/config/mosquitto.conf:ro"
    ];
  };
  extraConfig = {
    sops.secrets."mqtt/file" = {
      mode = "0444";
    };
  };
}
