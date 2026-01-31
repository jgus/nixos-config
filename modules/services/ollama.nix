{ config, lib, ... }:
{
  homelab.services.ollama = {
    container = {
      readOnly = false;
      pullImage = import ../../images/ollama.nix;
      ports = [
        "11434"
      ];
      configVolume = "/root/.ollama";
      devices = [
        "nvidia.com/gpu=GPU-8bb9f199-be89-462d-8e68-6ba4fe870ce4"
      ];
    };
  };

  fileSystems = lib.mkIf config.homelab.services.ollama.enable {
    "${lib.homelab.storagePath "ollama"}/models" = {
      device = "/s/ollama";
      fsType = "none";
      options = [ "bind" ];
    };
  };
}
