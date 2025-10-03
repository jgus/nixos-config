{ ... }:
{
  docker = {
    image = "ghcr.io/open-webui/open-webui:main";
    ports = [
      "8080"
    ];
    environment = {
      OLLAMA_BASE_URL = "http://ollama:11434";
    };
    configVolume = "/app/backend/data";
  };
}
