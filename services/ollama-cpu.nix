{ ... }:
{
  docker = {
    image = "alpine/ollama";
    ports = [
      "11434"
    ];
    configVolume = "/root/.ollama";
    volumes = [
      "/d/ollama/models:/root/.ollama/models"
    ];
  };
}
