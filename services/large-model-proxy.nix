# Large Model Proxy - manages multiple resource-heavy LLMs on the same machine
# https://github.com/perk11/large-model-proxy
{ pkgs, ... }:
let
  version = "0.7.1";
  # To update hashes when version changes:
  # 1. Update the version above
  # 2. Set gitHash = "" and vendorHash = ""
  # 3. Run nixos-rebuild (it will fail and display the correct hashes)
  # 4. Copy the correct hashes from the error message and update below
  gitHash = "sha256-FAu8YGJRH0V5kDCI5UezxE/A8N0XQI6c/jsqUvGBkzM=";
  vendorHash = "sha256-zMAapi6RDlXM7ewk8+vzUQftxGUy6PfBB27RQEeM+3A=";
  largeModelProxyPackage = pkgs.buildGoModule {
    pname = "large-model-proxy";
    inherit version;

    src = pkgs.fetchFromGitHub {
      owner = "perk11";
      repo = "large-model-proxy";
      rev = version;
      sha256 = gitHash;
    };

    inherit vendorHash;

    # Tests require the built binary during check phase, which doesn't exist yet
    doCheck = false;

    meta = with pkgs.lib; {
      description = "Proxy for managing multiple resource-heavy Large Models";
      homepage = "https://github.com/perk11/large-model-proxy";
      license = licenses.mit;
    };
  };

  # Configuration defined as Nix expression, will be converted to JSON
  configuration = {
    # Default URL template for services
    DefaultServiceUrl = "http://large-model-proxy:{{.PORT}}/";

    # OpenAI-compatible API endpoint
    # ListenHost empty = listen on all interfaces (IPv4 and IPv6)
    # Firewall restricts to macvlan interface only
    OpenAiApi = {
      ListenPort = "7070";
    };

    # Management/dashboard API
    ManagementApi = {
      ListenPort = "7071";
    };

    # Global settings
    MaxTimeToWaitForServiceToCloseConnectionBeforeGivingUpSeconds = 1200;
    ShutDownAfterInactivitySeconds = 600;

    # Available resources to allocate
    # Adjust these values based on your GPU(s) and system RAM
    ResourcesAvailable = {
      VRAM-GPU-1 = 24;
      RAM = 384;
    };

    # Services to proxy (example configuration - customize as needed)
    Services = [
      # Example: Ollama service
      # {
      #   Name = "ollama";
      #   OpenAiApi = true;
      #   ListenPort = "11434";
      #   ProxyTargetHost = "localhost";
      #   ProxyTargetPort = "21434";
      #   Command = "ollama";
      #   Args = "serve";
      #   HealthcheckCommand = "curl --fail http://localhost:21434/api/tags";
      #   HealthcheckIntervalMilliseconds = 500;
      #   RestartOnConnectionFailure = true;
      #   ResourceRequirements = {
      #     VRAM-GPU-1 = 20;
      #     RAM = 8;
      #   };
      # }
    ];
  };

  # Generate JSON config file
  configFile = (pkgs.formats.json { }).generate "config.json" configuration;
in
{
  configStorage = true;
  systemd = {
    macvlan = true;
    tcpPorts = [ 7070 7071 ];
    path = [ largeModelProxyPackage pkgs.curl ];
    script = { interface, ip, ip6, storagePath, name, ... }: ''
      cd ${storagePath name}
      exec large-model-proxy -c ${configFile}
    '';
  };
}
