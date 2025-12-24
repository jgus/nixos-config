{ pkgs, ... }:
let
  pw = import ./.secrets/passwords.nix;

  systemctlMqttPackage =
    { buildPythonApplication
    , fetchFromGitHub
    , setuptools
    , setuptools-scm
    , wheel
    , aiomqtt
    , jeepney
    }:
    buildPythonApplication {
      pname = "systemctl-mqtt";
      version = "1.1.0";
      src = fetchFromGitHub {
        owner = "jgus";
        repo = "systemctl-mqtt";
        rev = "1cd79ebc097133bd5c77828df5a750e64dea6aeb";
        sha256 = "sha256-qjgzT95vLbnGL2wn2sMqHODOfXfhXVyIwONp2zhxGiA=";
      };
      dependencies = [
        aiomqtt
        jeepney
      ];
      doCheck = false;
      pyproject = true;
      build-system = [
        setuptools
        setuptools-scm
        wheel
      ];
    };
in
{
  systemd.services = {
    systemctl-mqtt = {
      path = [
        pkgs.gawk
        (pkgs.python3.pkgs.callPackage systemctlMqttPackage { })
      ];
      script = ''
        systemctl-mqtt --mqtt-host mqtt.home.gustafson.me --mqtt-disable-tls --mqtt-username server --mqtt-password ${pw.mqtt.server} $(systemctl list-units --full --plain --no-legend --output=short docker-*.service | awk '{print "--monitor-system-unit " $1 " --control-system-unit " $1}')
      '';
      serviceConfig = {
        Type = "simple";
      };
      wantedBy = [ "multi-user.target" ];
      requires = [ "network-online.target" ];
    };
  };
}
