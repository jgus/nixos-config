{ ... }:
{
  docker = {
    image = "ollama/ollama";
    ports = [
      "11434"
    ];
    configVolume = "/root/.ollama";
    extraOptions = [
      "--device=nvidia.com/gpu=all"
    ];
  };
}
