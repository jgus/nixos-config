{ ... }:
{
  autoStart = false;
  docker = {
    image = "ollama/ollama";
    ports = [
      "11434"
    ];
    configVolume = "/root/.ollama";
    volumes = [
      "/storage/ollama/models:/root/.ollama/models"
    ];
    extraOptions = [
      "--device=nvidia.com/gpu=GPU-8bb9f199-be89-462d-8e68-6ba4fe870ce4"
    ];
    extraConfig = {
      fileSystems."/storage/ollama" = {
        device = "/s/ollama";
        fsType = "none";
        options = [ "bind" ];
      };
    };
  };
}
