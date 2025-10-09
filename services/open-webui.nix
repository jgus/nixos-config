{ ... }:
{
  docker = {
    # image = "ghcr.io/open-webui/open-webui:cuda";
    image = "ghcr.io/open-webui/open-webui";
    ports = [
      "8080"
    ];
    environment = {
      # OLLAMA_BASE_URL = "http://ollama:11434";
      OLLAMA_BASE_URL = "http://josh-pc:11434";
    };
    configVolume = "/app/backend/data";
    # extraOptions = [
    #   # "--device=nvidia.com/gpu=all"
    #   "--runtime=nvidia"
    #   "--gpus=all"
    # ];
  };
}
