with builtins;
let
  pw = import ./../.secrets/passwords.nix;
in
{ pkgs, ... }:
let
  passwordFileDer = pkgs.runCommandLocal "passwordFile" { } (concatStringsSep "\n" (
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
  docker = {
    pullImage =
      # nix-shell -p nix-prefetch-docker --run 'nix-prefetch-docker --quiet --image-name eclipse-mosquitto --image-tag latest'
      {
        imageName = "eclipse-mosquitto";
        imageDigest = "sha256:077fe4ff4c49df1e860c98335c77dda08360629e0e2a718147027e4db3eace9d";
        hash = "sha256-txxzwvqBaRRtBDgHiUZuaAyNlUqx0g7MMiMwaaAQ7B4=";
        finalImageName = "eclipse-mosquitto";
        finalImageTag = "latest";
      };
    configVolume = "/mosquitto/data";
    ports = [
      "1883"
      "9001"
    ];
    volumes = [
      "${passwordFileDer}/password.conf:/mosquitto/config/password_file.conf:ro"
      "${aclFile}:/mosquitto/config/acl_file.conf:ro"
      "${configFile}:/mosquitto/config/mosquitto.conf:ro"
    ];
    extraOptions = [
      "--read-only"
    ];
  };
}
