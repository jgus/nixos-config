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
      VRAM-1 = 24;
      RAM = 384;
    };

    # Services to proxy (example configuration - customize as needed)
    Services = [
      # DeepSeek-V3.1-Terminus via llama.cpp
      # https://docs.unsloth.ai/models/deepseek-v3.1-how-to-run-locally
      (
        let
          name = "deepseek-v3-terminus";
          localPort = 8080;
          exposePort = 8080;
          ip = "${dockerNetworkPrefix}2";
          containerName = "lmp-${name}";
        in
        {
          Name = "DeepSeek V3.1 Terminus (UD-Q2_K_XL)";
          OpenAiApi = true;
          ListenPort = toString exposePort;
          ProxyTargetHost = ip;
          ProxyTargetPort = toString localPort;
          Command = "docker";
          Args = lib.concatStringsSep " " [
            "run"

            ### Begin Docker Args ###

            "--rm"
            "--read-only"
            "--name=${containerName}"
            "--network=${dockerNetworkName}"
            "--ip=${ip}"
            "--device=nvidia.com/gpu=GPU-8bb9f199-be89-462d-8e68-6ba4fe870ce4"
            "--cap-add IPC_LOCK"
            # NUMA Binding - GPU on PCIe connected to CPU 2 (NUMA node 1)
            "--cpuset-cpus=${numaCpusNearGpu1}"
            "-v /storage/llama.cpp:/root/.cache/llama.cpp"

            ### End Docker Args ###

            "ghcr.io/ggml-org/llama.cpp:server-cuda"

            ### Begin Llama.cpp Args ###

            "--port ${toString localPort}"

            # CPU Threading
            "--threads ${toString numaCpuCountPerNode}"
            "--threads-batch ${toString numaCpuCountPerNode}"
            # Model
            "-hf unsloth/DeepSeek-V3.1-Terminus-GGUF:UD-Q2_K_XL"
            "--jinja"
            # Sampling Parameters
            "--temp 0.6"
            "--top-p 0.95"
            "--min-p 0.01"
            # Batch Size for Prompt Processing
            "--batch-size 8192"
            "--ubatch-size 2048"
            # Context Size
            "--ctx-size ${toString (32 * 1024)}"
            # KV Cache Quantization
            "--cache-type-k q8_0"
            "--cache-type-v q8_0"
            # Flash Attention
            "--flash-attn on"
            # "Everything" on GPU...
            "--n-gpu-layers 999"
            # ...except MoE Offloading (ie most of it)
            "-ot .ffn_.*_exps.=CPU"
            # Prompt Caching
            "--slot-save-path /root/.cache/llama.cpp/prompt-cache"
            "--mlock"

            ### End Llama.cpp Args ###
          ];
          HealthcheckCommand = "docker exec ${containerName} curl --fail http://localhost:${toString localPort}/health";
          HealthcheckIntervalMilliseconds = 10000;
          StartupTimeoutMilliseconds = 30 * 60 * 1000;
          KillCommand = "docker stop ${containerName}";
          RestartOnConnectionFailure = true;
          ResourceRequirements = {
            VRAM-1 = 21;
            RAM = 231;
          };
        }
      )

      # Kimi K2 Instruct via llama.cpp
      # https://docs.unsloth.ai/models/kimi-k2-thinking-how-to-run-locally
      (
        let
          name = "kimi-k2-instruct";
          localPort = 8080;
          exposePort = 8081;
          ip = "${dockerNetworkPrefix}3";
          containerName = "lmp-${name}";
        in
        {
          Name = "Kimi K2 Instruct (UD-Q2_K_XL)";
          OpenAiApi = true;
          ListenPort = toString exposePort;
          ProxyTargetHost = ip;
          ProxyTargetPort = toString localPort;
          Command = "docker";
          Args = lib.concatStringsSep " " [
            "run"

            ### Begin Docker Args ###

            "--rm"
            "--read-only"
            "--name=${containerName}"
            "--network=${dockerNetworkName}"
            "--ip=${ip}"
            "--device=nvidia.com/gpu=GPU-8bb9f199-be89-462d-8e68-6ba4fe870ce4"
            "--cap-add IPC_LOCK"
            # NUMA Binding - GPU on PCIe connected to CPU 2 (NUMA node 1)
            "--cpuset-cpus=${numaCpusNearGpu1}"
            "-v /storage/llama.cpp:/root/.cache/llama.cpp"

            ### End Docker Args ###

            "ghcr.io/ggml-org/llama.cpp:server-cuda"

            ### Begin Llama.cpp Args ###

            "--port ${toString localPort}"

            # CPU Threading
            "--threads ${toString numaCpuCountPerNode}"
            "--threads-batch ${toString numaCpuCountPerNode}"
            # Model
            "-hf unsloth/Kimi-K2-Instruct-GGUF:UD-Q2_K_XL"
            "--jinja"
            # Sampling Parameters
            "--temp 0.6"
            "--min-p 0.01"
            # Batch Size for Prompt Processing
            "--batch-size 8192"
            "--ubatch-size 2048"
            # Context Size
            "--ctx-size ${toString (16 * 1024)}"
            # KV Cache Quantization
            "--cache-type-k q8_0"
            "--cache-type-v q8_0"
            # Flash Attention
            "--flash-attn on"
            # "Everything" on GPU...
            "--n-gpu-layers 999"
            # ...except MoE Offloading (ie most of it)
            "-ot .ffn_.*_exps.=CPU"
            # Prompt Caching
            "--slot-save-path /root/.cache/llama.cpp/prompt-cache"
            "--mlock"

            ### End Llama.cpp Args ###
          ];
          HealthcheckCommand = "docker exec ${containerName} curl --fail http://localhost:${toString localPort}/health";
          HealthcheckIntervalMilliseconds = 10000;
          StartupTimeoutMilliseconds = 30 * 60 * 1000;
          KillCommand = "docker stop ${containerName}";
          RestartOnConnectionFailure = true;
          ResourceRequirements = {
            VRAM-1 = 20;
            RAM = 362;
          };
        }
      )

      # Kimi K2 Thinking via llama.cpp
      # https://docs.unsloth.ai/models/kimi-k2-thinking-how-to-run-locally
      (
        let
          name = "kimi-k2-thinking";
          localPort = 8080;
          exposePort = 8082;
          ip = "${dockerNetworkPrefix}4";
          containerName = "lmp-${name}";
        in
        {
          Name = "Kimi K2 Thinking (UD-Q2_K_XL)";
          OpenAiApi = true;
          ListenPort = toString exposePort;
          ProxyTargetHost = ip;
          ProxyTargetPort = toString localPort;
          Command = "docker";
          Args = lib.concatStringsSep " " [
            "run"

            ### Begin Docker Args ###

            "--rm"
            "--read-only"
            "--name=${containerName}"
            "--network=${dockerNetworkName}"
            "--ip=${ip}"
            "--device=nvidia.com/gpu=GPU-8bb9f199-be89-462d-8e68-6ba4fe870ce4"
            "--cap-add IPC_LOCK"
            # NUMA Binding - GPU on PCIe connected to CPU 2 (NUMA node 1)
            "--cpuset-cpus=${numaCpusNearGpu1}"
            "-v /storage/llama.cpp:/root/.cache/llama.cpp"

            ### End Docker Args ###

            "ghcr.io/ggml-org/llama.cpp:server-cuda"

            ### Begin Llama.cpp Args ###

            "--port ${toString localPort}"

            # CPU Threading
            "--threads ${toString numaCpuCountPerNode}"
            "--threads-batch ${toString numaCpuCountPerNode}"
            # Model
            "-hf unsloth/Kimi-K2-Thinking-GGUF:UD-Q2_K_XL"
            "--jinja"
            # Sampling Parameters - Note: temp 1.0 for Thinking model
            "--temp 1.0"
            "--min-p 0.01"
            # Batch Size for Prompt Processing
            "--batch-size 8192"
            "--ubatch-size 2048"
            # Context Size - Recommended 98,304 for Thinking
            "--ctx-size ${toString (96 * 1024)}"
            # KV Cache Quantization
            "--cache-type-k q8_0"
            "--cache-type-v q8_0"
            # Flash Attention
            "--flash-attn on"
            # "Everything" on GPU...
            "--n-gpu-layers 999"
            # ...except MoE Offloading (ie most of it)
            "-ot .ffn_.*_exps.=CPU"
            # Prompt Caching
            "--slot-save-path /root/.cache/llama.cpp/prompt-cache"
            # Special flag to show thinking tags
            "--special"
            "--mlock"

            ### End Llama.cpp Args ###
          ];
          HealthcheckCommand = "docker exec ${containerName} curl --fail http://localhost:${toString localPort}/health";
          HealthcheckIntervalMilliseconds = 10000;
          StartupTimeoutMilliseconds = 30 * 60 * 1000;
          KillCommand = "docker stop ${containerName}";
          RestartOnConnectionFailure = true;
          ResourceRequirements = {
            VRAM-1 = 20;
            RAM = 366;
          };
        }
      )

      # ComfyUI - Stable Diffusion GUI
      (
        let
          name = "comfyui";
          localPort = 8188;
          exposePort = 8188;
          ip = "${dockerNetworkPrefix}5";
          containerName = "lmp-${name}";

          # Wrapper script that builds image (cached) then runs container
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
      #     VRAM-1 = 20;
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
