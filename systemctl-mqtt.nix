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
    buildPythonApplication rec {
      pname = "systemctl-mqtt";
      version = "1.1.0";
      src = fetchFromGitHub {
        owner = "jgus";
        repo = "systemctl-mqtt";
        rev = "4e8e9acc4ae8d46b543b2d9f4ab51d75728e1a2f";
        sha256 = "sha256-UH8GdLBkee0RwGi1Ee5nZf/fF4LdeDPUsayvOOj46Ks=";
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
