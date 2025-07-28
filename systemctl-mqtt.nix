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
    , fetchPypi
    , setuptools
    , setuptools-scm
    , wheel
    , aiomqtt
    , jeepney
    }:
    buildPythonApplication rec {
      pname = "systemctl-mqtt";
      version = "1.1.0";
      src = fetchPypi {
        inherit pname version;
        hash = "sha256-JFx05LQIqrA2W2r7wzP7dwWDY7cutMGcS42DpM0gGsw=";
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
        (python.pkgs.callPackage systemctlMqttPackage { })
      ];
      script = ''
        systemctl-mqtt --mqtt-host mqtt.home.gustafson.me --mqtt-disable-tls --mqtt-username server --mqtt-password ${pw.mqtt.server} --monitor-system-unit docker-esphome.service --control-system-unit docker-esphome.service
      '';
      serviceConfig = {
        Type = "simple";
      };
      wantedBy = [ "multi-user.target" ];
      requires = [ "network-online.target" ];
    };
  };
}
