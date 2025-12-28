{ pkgs, ... }:
{
  docker = {
    # image = "ghcr.io/open-webui/open-webui:cuda";
    image = "ghcr.io/open-webui/open-webui";
    imageFile = pkgs.dockerTools.pullImage
      # nix-shell -p nix-prefetch-docker --run 'nix-prefetch-docker --quiet --image-name ghcr.io/open-webui/open-webui --image-tag latest'
      {
        imageName = "ghcr.io/open-webui/open-webui";
        imageDigest = "sha256:18c1475e636245e2f439b59b4a2b38e1965c881856092d21e5efc38da7e1dac3";
        hash = "sha256-Oo79n9gfI1kPV+d0qU2Iaea4A0JjoAk/7WOImWwURiY=";
        finalImageName = "ghcr.io/open-webui/open-webui";
        finalImageTag = "latest";
      };
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
