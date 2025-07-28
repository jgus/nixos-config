{ pkgs, ... }:
let
  pw = import ./.secrets/passwords.nix;

  python = pkgs.python3.override {
    self = python;
    packageOverrides = pyfinal: pyprev: {
      jeepney = pyprev.jeepney.overridePythonAttrs (old: rec {
        version = "0.8.0";
        src = pkgs.fetchPypi {
          pname = "jeepney";
          inherit version;
          hash = "sha256-Xv5I0lWXOQL2utw85V4qpsXDs7xkIFnvOpEke8/MWAY=";
        };
        propagatedBuildInputs = with pyprev; [
          outcome
          trio
        ];
        doCheck = false;
      });
    };
  };

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
        rev = "e69f34c444dbb3a5fffd113e9439e46068c256ab";
        sha256 = "sha256-cDTjgJDCTFn/fQ4Q09txdZbM0iiFm+OSHgDI1L7OP2Q=";
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
        (python.pkgs.callPackage systemctlMqttPackage { })
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
