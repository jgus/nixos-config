{ ... }:
{
  docker = {
    image = "ollama/ollama";
    ports = [
      "11434"
    ];
    configVolume = "/root/.ollama";
    volumes = [
      "/d/ollama/models:/root/.ollama/models"
    ];
    extraOptions = [
      "--device=nvidia.com/gpu=all"
    ];
  };
}
