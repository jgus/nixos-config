{ ... }:
{
  autoStart = false;
  docker = {
    pullImage =
      # nix-shell -p nix-prefetch-docker --run 'nix-prefetch-docker --quiet --image-name ollama/ollama --image-tag latest'
      {
        imageName = "ollama/ollama";
        imageDigest = "sha256:2c9595c555fd70a28363489ac03bd5bf9e7c5bdf2890373c3a830ffd7252ce6d";
        hash = "sha256-syi7Of+G+vceyOL91S18LonmHqp+iEwtvH277XW++2U=";
        finalImageName = "ollama/ollama";
        finalImageTag = "latest";
      };
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
