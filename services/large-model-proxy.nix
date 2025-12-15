# Large Model Proxy - manages multiple resource-heavy LLMs on the same machine
# https://github.com/perk11/large-model-proxy
{ pkgs, lib, ... }:
let
  machine = import ../machine.nix;
  numaCpusStrs = map (cpuSet: lib.concatMapStringsSep "," toString cpuSet) machine.numaCpus;
  numaCpusNearGpu1 = (builtins.elemAt numaCpusStrs 1);
  numaCpuCountPerNode = builtins.length (builtins.elemAt machine.numaCpus 0);

  # Docker network configuration
  dockerNetworkName = "lmp-network";
  dockerNetworkPrefix = "192.168.88.";

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

  llamaCppServices = [
    # DeepSeek-V3.1-Terminus via llama.cpp
    # https://docs.unsloth.ai/models/deepseek-v3.1-how-to-run-locally
    {
      name = "deepseek-v3-terminus";
      displayName = "DeepSeek V3.1 Terminus (UD-Q2_K_XL)";
      model = "unsloth/DeepSeek-V3.1-Terminus-GGUF:UD-Q2_K_XL";
      resourceRequirements = {
        VRAM-1 = 21;
        RAM = 231;
      };
      extraLlamaCppArgs = [
        # Sampling Parameters
        "--temp 0.6"
        "--top-p 0.95"
        "--min-p 0.01"
        # GPU Settings
        "--n-gpu-layers 999"
        "-ot .ffn_.*_exps.=CPU"
      ];
    }

    # Kimi K2 Instruct via llama.cpp
    # https://docs.unsloth.ai/models/kimi-k2-thinking-how-to-run-locally
    {
      name = "kimi-k2-instruct";
      displayName = "Kimi K2 Instruct (UD-Q2_K_XL)";
      model = "unsloth/Kimi-K2-Instruct-GGUF:UD-Q2_K_XL";
      ctxSize = 16 * 1024;
      resourceRequirements = {
        VRAM-1 = 20;
        RAM = 362;
      };
      extraLlamaCppArgs = [
        # Sampling Parameters
        "--temp 0.6"
        "--min-p 0.01"
        # GPU Settings
        "--n-gpu-layers 999"
        "-ot .ffn_.*_exps.=CPU"
      ];
    }

    # Kimi K2 Thinking via llama.cpp
    # https://docs.unsloth.ai/models/kimi-k2-thinking-how-to-run-locally
    {
      name = "kimi-k2-thinking";
      displayName = "Kimi K2 Thinking (UD-Q2_K_XL)";
      model = "unsloth/Kimi-K2-Thinking-GGUF:UD-Q2_K_XL";
      ctxSize = 96 * 1024;
      resourceRequirements = {
        VRAM-1 = 20;
        RAM = 366;
      };
      extraLlamaCppArgs = [
        # Sampling Parameters - Note: temp 1.0 for Thinking model
        "--temp 1.0"
        "--min-p 0.01"
        # GPU Settings
        "--n-gpu-layers 999"
        "-ot .ffn_.*_exps.=CPU"
        # Special flag to show thinking tags
        "--special"
      ];
    }
  ];

  # Auto-increment settings for llama.cpp services
  llamaCppBaseIpSuffix = 11; # First service gets 192.168.88.11
  llamaCppBaseExposePort = 8081; # First service gets port 8081

  # Helper function to create llamacpp service configurations
  # Takes index i and service config, auto-computes ipSuffix and exposePort
  llamaCppService = i: svc:
    let
      localPort = svc.localPort or 8080;
      ip = "${dockerNetworkPrefix}${toString (llamaCppBaseIpSuffix + i)}";
      containerName = "lmp-${svc.name}";
    in
    {
      Name = svc.displayName;
      OpenAiApi = true;
      ListenPort = toString (llamaCppBaseExposePort + i);
      ProxyTargetHost = ip;
      ProxyTargetPort = toString localPort;
      Command = "docker";
      Args = lib.concatStringsSep " " (
        # Docker arguments
        [
          "run"
          "--rm"
          "--read-only"
          "--name=${containerName}"
          "--network=${dockerNetworkName}"
          "--ip=${ip}"
          "--device=nvidia.com/gpu=GPU-8bb9f199-be89-462d-8e68-6ba4fe870ce4"
          "--cap-add IPC_LOCK"
          "--cpuset-cpus=${numaCpusNearGpu1}"
          "-v /storage/llama.cpp:/root/.cache/llama.cpp"
          "ghcr.io/ggml-org/llama.cpp:server-cuda"
        ]
        # Llama.cpp arguments
        ++ [
          "--port ${toString localPort}"
          "--threads ${toString numaCpuCountPerNode}"
          "--threads-batch ${toString numaCpuCountPerNode}"
          "-hf ${svc.model}"
          "--jinja"
        ]
        ++ (svc.extraLlamaCppArgs or [ ])
        ++ [
          "--batch-size ${toString (svc.batchSize or 8192)}"
          "--ubatch-size ${toString (svc.ubatchSize or 2048)}"
          "--ctx-size ${toString (svc.ctxSize or (32 * 1024))}"
          "--cache-type-k q8_0"
          "--cache-type-v q8_0"
          "--flash-attn on"
          "--slot-save-path /root/.cache/llama.cpp/prompt-cache"
          "--mlock"
        ]
      );
      HealthcheckCommand = "docker exec ${containerName} curl --fail http://localhost:${toString localPort}/health";
      HealthcheckIntervalMilliseconds = 10000;
      StartupTimeoutMilliseconds = 30 * 60 * 1000;
      KillCommand = "docker stop ${containerName}";
      RestartOnConnectionFailure = true;
      ResourceRequirements = svc.resourceRequirements;
    };

  # Configuration defined as Nix expression, will be converted to JSON
  configuration = {
    # Default URL template for services
    DefaultServiceUrl = "http://large-model-proxy:{{.PORT}}/";

    # OpenAI-compatible API endpoint
    OpenAiApi = {
      ListenPort = "7070";
    };

    # Management/dashboard API
    ManagementApi = {
      ListenPort = "7071";
    };

    # Global settings
    MaxTimeToWaitForServiceToCloseConnectionBeforeGivingUpSeconds = 15;
    ShutDownAfterInactivitySeconds = 24 * 60 * 60;

    # Available resources to allocate
    # Adjust these values based on your GPU(s) and system RAM
    ResourcesAvailable = {
      VRAM-1 = 24;
      RAM = 384;
    };

    # Services to proxy (example configuration - customize as needed)
    Services =
      [
        # ComfyUI - Stable Diffusion GUI
        (
          let
            localPort = 8188;
            exposePort = 8188;
            ip = "${dockerNetworkPrefix}2";
            containerName = "lmp-comfyui";

            launchScript = pkgs.writeShellScript "comfyui-launch" ''
              set -e
            
              # Build image (will use cache if Dockerfile unchanged)
              echo "Building ComfyUI image (using cache if available)..."
              docker build -t comfyui:local /etc/nixos/containers/comfyui
            
              # Run container
              exec docker run \
                --rm \
                --name=${containerName} \
                --network=${dockerNetworkName} \
                --ip=${ip} \
                --device=nvidia.com/gpu=GPU-8bb9f199-be89-462d-8e68-6ba4fe870ce4 \
                -v /storage/comfyui/models:/app/comfyui/models \
                -v /storage/comfyui/output:/app/comfyui/output \
                -v /storage/comfyui/custom_nodes:/app/comfyui/custom_nodes \
                comfyui:local
            '';
          in
          {
            Name = "ComfyUI";
            ListenPort = toString exposePort;
            ProxyTargetHost = ip;
            ProxyTargetPort = toString localPort;
            Command = toString launchScript;
            Args = "";
            HealthcheckCommand = "docker exec ${containerName} curl --fail http://localhost:${toString localPort}";
            HealthcheckIntervalMilliseconds = 10000;
            StartupTimeoutMilliseconds = 30 * 60 * 1000; # 5 minutes for first build
            KillCommand = "docker stop -t 5 ${containerName}"; # Graceful shutdown
            RestartOnConnectionFailure = true;
            ShutDownAfterInactivitySeconds = 600;
            ResourceRequirements = {
              VRAM-1 = 20;
              RAM = 16;
            };
          }
        )
      ]
      ++
      # Llama.cpp Services
      (lib.imap0 llamaCppService llamaCppServices)
    ;
  };

  # Generate JSON config file
  configFile = (pkgs.formats.json { }).generate "config.json" configuration;
in
{
  configStorage = true;
  systemd = {
    extraStorage = [ "comfyui " ];
    macvlan = true;
    tcpPorts = [ 7070 7071 8080 8081 8082 8188 ];
    path = [ largeModelProxyPackage pkgs.curl pkgs.docker pkgs.bash ];
    script = { interface, ip, ip6, storagePath, name, ... }: ''
      # Create dedicated Docker network for LMP if it doesn't exist
      if ! docker network inspect ${dockerNetworkName} >/dev/null 2>&1; then
        echo "Creating Docker network: ${dockerNetworkName}"
        docker network create --driver=bridge --subnet=${dockerNetworkPrefix}0/24 --gateway=${dockerNetworkPrefix}1 ${dockerNetworkName}
      fi

      cd ${storagePath name}
      exec large-model-proxy -c ${configFile}
    '';
  };
}
