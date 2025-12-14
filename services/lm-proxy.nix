# Large Model Proxy - manages multiple resource-heavy LLMs on the same machine
# https://github.com/perk11/large-model-proxy
{ pkgs, ... }:
let
  # Note: IPv4 macvlan has network issues, IPv6 works
  # Service listens on all interfaces; firewall restricts to macvlan only

  # Build large-model-proxy from source with ListenHost patch
  large-model-proxy = pkgs.buildGoModule rec {
    pname = "large-model-proxy";
    version = "0.7.1";

    src = pkgs.fetchFromGitHub {
      owner = "perk11";
      repo = "large-model-proxy";
      rev = "0.7.1";
      sha256 = "sha256-FAu8YGJRH0V5kDCI5UezxE/A8N0XQI6c/jsqUvGBkzM=";
    };

    vendorHash = "sha256-zMAapi6RDlXM7ewk8+vzUQftxGUy6PfBB27RQEeM+3A=";

    # Tests require the built binary during check phase, which doesn't exist yet
    doCheck = false;

    # Add ListenHost support for binding to specific IP addresses
    postPatch = ''
      # Add ListenHost field after Name in ServiceConfig struct
      sed -i '/type ServiceConfig struct {/,/^}/ s/Name\s*string/Name                            string\n\tListenHost                      string/' config.go

      # Add ListenHost field to OpenAiApi struct
      sed -i 's/type OpenAiApi struct {\n\tListenPort/type OpenAiApi struct {\n\tListenHost string\n\tListenPort/' config.go
      sed -i '/type OpenAiApi struct {/,/^}/ s/ListenPort string/ListenHost string\n\tListenPort string/' config.go

      # Add ListenHost field to ManagementApi struct  
      sed -i '/type ManagementApi struct {/,/^}/ s/ListenPort string/ListenHost string\n\tListenPort string/' config.go

      # Update OpenAI API listener to use ListenHost
      sed -i 's/Addr:    ":" + OpenAiApi.ListenPort,/Addr:    OpenAiApi.ListenHost + ":" + OpenAiApi.ListenPort,/' main.go

      # Update proxy listener to use ListenHost
      sed -i 's/net.Listen("tcp", ":"+serviceConfig.ListenPort)/net.Listen("tcp", serviceConfig.ListenHost+":"+serviceConfig.ListenPort)/' main.go

      # Update Management API listener to use ListenHost
      sed -i 's/Addr:    ":" + managementAPI.ListenPort,/Addr:    managementAPI.ListenHost + ":" + managementAPI.ListenPort,/' management_api.go
    '';

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
      ListenHost = "";
      ListenPort = "7070";
    };

    # Management/dashboard API
    ManagementApi = {
      ListenHost = "";
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
    path = [ large-model-proxy pkgs.curl ];
    script = { interface, ip, ip6, storagePath, name, ... }: ''
      # Create logs directory
      mkdir -p ${storagePath name}/logs

      # Start large-model-proxy
      cd ${storagePath name}
      exec large-model-proxy -c ${configFile}
    '';
  };
  extraConfig = {
    # Open firewall ports on the macvlan interface
    networking.firewall.interfaces."mv-lm-proxy".allowedTCPPorts = [ 7070 7071 ];
  };
}
