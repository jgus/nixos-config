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
      # NVIDIA_VISIBLE_DEVICES = "GPU-8bb9f199-be89-462d-8e68-6ba4fe870ce4";
    };
    configVolume = "/app/backend/data";
    # extraOptions = [
    #   # "--device=nvidia.com/gpu=GPU-8bb9f199-be89-462d-8e68-6ba4fe870ce4"
    #   "--runtime=nvidia"
    #   "--gpus=GPU-8bb9f199-be89-462d-8e68-6ba4fe870ce4"
    # ];
  };
}
