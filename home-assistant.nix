{ pkgs, ... }:

{
  imports = [ ./cec.nix ];

  services.home-assistant = {
    enable = true;
    openFirewall = true;
    extraComponents = [
      "default_config"
      "met"
      "esphome"
      "hdmi_cec"
    ];
    config = {
      homeassistant = {
        name = "Theater Control";
        unit_system = "imperial";
        time_zone = "America/Denver";
      };
    };
  };
}
