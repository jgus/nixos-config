{ pkgs, ... }:
{
  # SillyTavern - Feature-rich RP/chat frontend
  # Web UI at http://sillytavern:8000
  #
  # Features:
  # - Character cards and personas
  # - World info/lorebooks
  # - Author's notes
  # - Multiple backend support (llama.cpp, KoboldCpp, Ollama, etc.)
  # - Prompt template customization
  # - Chat history management
  #
  # Backend Configuration:
  # In SillyTavern, go to API Connections and configure:
  #
  # For llama.cpp server:
  #   API Type: Text Completion API (llama.cpp)
  #   Server URL: http://llama-cpp-ds-3-1-terminus:8080
  #
  # For KoboldCpp:
  #   API Type: KoboldAI
  #   Server URL: http://koboldcpp:5001
  #
  # For Ollama:
  #   API Type: Ollama
  #   Server URL: http://ollama:11434

  configStorage = true;
  docker = {
    image = "ghcr.io/sillytavern/sillytavern:latest";
    imageFile = pkgs.dockerTools.pullImage
      # nix-shell -p nix-prefetch-docker --run 'nix-prefetch-docker --quiet --image-name ghcr.io/sillytavern/sillytavern --image-tag latest'
      {
        imageName = "ghcr.io/sillytavern/sillytavern";
        imageDigest = "sha256:8dc43050b9e0036e0eb106a0c0f943763ef4c071139613c49c3237599d8c4f7d";
        hash = "sha256-/XR/GOhh1jmYeOGfIj6DYvzZvkLPWNbWKzEPVHIWRdI=";
        finalImageName = "ghcr.io/sillytavern/sillytavern";
        finalImageTag = "latest";
      };
    configVolume = "/home/node/app/config";
    ports = [
      "80"
    ];
    volumes = storagePath: [
      # Plugins directory
      "${storagePath "sillytavern"}/plugins:/home/node/app/plugins"
      # User images/avatars
      "${storagePath "sillytavern"}/public:/home/node/app/public/user"
    ];
  };
}
