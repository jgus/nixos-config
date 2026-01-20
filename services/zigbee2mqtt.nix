{ ... }:
{
  container = {
    pullImage = import ../images/zigbee2mqtt.nix;
    configVolume = "/app/data";
    ports = [
      "8081"
    ];
  };
}
