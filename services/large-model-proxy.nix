# Large Model Proxy - manages multiple resource-heavy LLMs on the same machine
# https://github.com/perk11/large-model-proxy
{ pkgs, lib, ... }:
let
  machine = import ../machine.nix;
  numaCpusStrs = map (cpuSet: lib.concatMapStringsSep "," toString cpuSet) machine.numaCpus;
  numaCpusNearGpu1 = (builtins.elemAt numaCpusStrs 1);
  numaCpusNotNearGpu1 = (builtins.elemAt numaCpusStrs 0);
  numaCpuCountPerNode = builtins.length (builtins.elemAt machine.numaCpus 0);

  # Docker network configuration
  dockerNetworkName = "lmp-network";
  dockerNetworkPrefix = "192.168.88.";

  version = "jgus";
  # To update hashes when version changes:
  # 1. Update the version above
  # 2. Set gitHash = "" and vendorHash = ""
  # 3. Run nixos-rebuild (it will fail and display the correct hashes)
  # 4. Copy the correct hashes from the error message and update below
  gitHash = "sha256-1fe4goxvIFesXYY7y0Tezn00HJ1dM/8WsD08LNi9Ga0=";
  vendorHash = "sha256-tu1nSSZbsPPIrYaiwnQEXeLZoUTnWfCJmIxr08fNPVs=";
  largeModelProxyPackage = pkgs.buildGoModule {
    pname = "large-model-proxy";
    inherit version;

    src = pkgs.fetchFromGitHub {
      owner = "jgus";
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

  # Auto-increment settings for llama.cpp services
  llamaCppBaseIpSuffix = 11; # First service gets 192.168.88.11

  # Helper function to create llamacpp service configurations
  # Takes index i and service config, auto-computes ipSuffix and exposePort
  llamaCppService = i: service:
    let
      localPort = service.localPort or 8080;
      ip = "${dockerNetworkPrefix}${toString (llamaCppBaseIpSuffix + i)}";
      containerName = "lmp-${service.name}";
      gpu = service.gpu;
      loadTimeSeconds = builtins.ceil (((service.resourceRequirements.VRAM-1 or 0) + (service.resourceRequirements.RAM or 0)) / 0.400);
      initTimeSeconds = 10 * 60;
    in
    {
      Name = service.displayName;
      OpenAiApi = true;
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
          (lib.optionalString gpu "--device=nvidia.com/gpu=GPU-8bb9f199-be89-462d-8e68-6ba4fe870ce4")
          "--cap-add IPC_LOCK"
          "--cpuset-cpus=${if gpu then numaCpusNearGpu1 else numaCpusNotNearGpu1}"
          "-v /storage/llama.cpp:/root/.cache/llama.cpp"
          "ghcr.io/ggml-org/llama.cpp:${if gpu then "server-cuda" else "server"}"
        ]
        # Llama.cpp arguments
        ++ [
          "--port ${toString localPort}"
          "--threads ${toString numaCpuCountPerNode}"
          "--threads-batch ${toString numaCpuCountPerNode}"
          "-hf ${service.model}"
          "--jinja"
        ]
        ++ (service.extraLlamaCppArgs or [ ])
        ++ [
          "--batch-size ${toString (service.batchSize or 8192)}"
          "--ubatch-size ${toString (service.ubatchSize or 2048)}"
          "--ctx-size ${toString (service.contextSize or 0)}"
          "--parallel 1"
          "-kvu"
          "--cache-type-k q8_0"
          "--cache-type-v q8_0"
          "--flash-attn on"
          "--slot-save-path /root/.cache/llama.cpp/prompt-cache"
          "--mlock"
        ]
      );
      HealthcheckCommand = "docker exec ${containerName} curl --fail http://localhost:${toString localPort}/health";
      HealthcheckIntervalMilliseconds = 10000;
      StartupTimeoutMilliseconds = (loadTimeSeconds + initTimeSeconds) * 1000;
      KillCommand = "docker stop ${containerName}";
      RestartOnConnectionFailure = true;
      ResourceRequirements = service.resourceRequirements;
    };

  # Configuration defined as Nix expression, will be converted to JSON
  configuration = { hostIp, hostIp6 }: {
    # Default URL template for services
    DefaultServiceUrl = "http://large-model-proxy:{{.PORT}}/";

    # OpenAI-compatible API endpoint
    OpenAiApi = {
      ListenAddresses = [ hostIp hostIp6 ];
      ListenPort = "8080";
    };

    # Management/dashboard API
    ManagementApi = {
      ListenAddresses = [ hostIp hostIp6 ];
      ListenPort = "80";
    };

    # Global settings
    MaxTimeToWaitForServiceToCloseConnectionBeforeGivingUpSeconds = 30;
    ShutDownAfterInactivitySeconds = 24 * 60 * 60;

    # Available resources to allocate
    # Adjust these values based on your GPU(s) and system RAM
    ResourcesAvailable = {
      VRAM-1 = 24;
      RAM = 448;
    };

    OutputServiceLogs = false;

    # Services to proxy (example configuration - customize as needed)
    Services = [
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
            docker build -t comfyui:local ${./large-model-proxy/comfyui}
            
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
          ListenAddresses = [ hostIp hostIp6 ];
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
    (lib.imap0 llamaCppService [
      # https://docs.unsloth.ai/models/deepseek-v3.1-how-to-run-locally
      {
        name = "deepseek-v3-terminus";
        displayName = "DeepSeek V3.1 Terminus";
        model = "unsloth/DeepSeek-V3.1-Terminus-GGUF:UD-Q2_K_XL";
        gpu = true;
        resourceRequirements = {
          VRAM-1 = 24;
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

      # https://docs.unsloth.ai/models/gpt-oss-how-to-run-and-fine-tune
      {
        name = "gpt-oss-20b";
        displayName = "gpt-oss 20B";
        model = "unsloth/gpt-oss-20b-GGUF:Q8_K_XL";
        gpu = true;
        resourceRequirements = {
          VRAM-1 = 15;
        };
        extraLlamaCppArgs = [
          # Sampling Parameters
          "--temp 1.0"
          "--top-p 1.0"
          "--top-k 0.0"
          # GPU Settings
          "--n-gpu-layers 999"
        ];
      }

      # https://docs.unsloth.ai/models/gpt-oss-how-to-run-and-fine-tune
      {
        name = "gpt-oss-120b";
        displayName = "gpt-oss 120B";
        model = "unsloth/gpt-oss-120b-GGUF:Q4_K_XL";
        gpu = false;
        resourceRequirements = {
          RAM = 62;
        };
        extraLlamaCppArgs = [
          # Sampling Parameters
          "--temp 1.0"
          "--min-p 0.0"
          "--top-p 1.0"
          "--top-k 0.0"
        ];
      }

      # https://docs.unsloth.ai/models/kimi-k2-thinking-how-to-run-locally
      {
        name = "kimi-k2-instruct";
        displayName = "Kimi K2 Instruct";
        model = "unsloth/Kimi-K2-Instruct-GGUF:UD-Q2_K_XL";
        gpu = true;
        resourceRequirements = {
          VRAM-1 = 22;
          RAM = 362;
        };
        contextSize = 128 * 1024;
        extraLlamaCppArgs = [
          # Sampling Parameters
          "--temp 0.6"
          "--min-p 0.01"
          # GPU Settings
          "--n-gpu-layers 999"
          "-ot .ffn_.*_exps.=CPU"
        ];
      }

      # https://docs.unsloth.ai/models/kimi-k2-thinking-how-to-run-locally
      {
        name = "kimi-k2-thinking";
        displayName = "Kimi K2 Thinking";
        model = "unsloth/Kimi-K2-Thinking-GGUF:UD-Q2_K_XL";
        gpu = true;
        resourceRequirements = {
          VRAM-1 = 22;
          RAM = 366;
        };
        contextSize = 128 * 1024;
        extraLlamaCppArgs = [
          # Sampling Parameters
          "--temp 1.0"
          "--min-p 0.01"
          # GPU Settings
          "--n-gpu-layers 999"
          "-ot .ffn_.*_exps.=CPU"
          # Special flag to show thinking tags
          "--special"
        ];
      }

      # https://docs.unsloth.ai/models/kimi-k2-thinking-how-to-run-locally
      {
        name = "kimi-k2-thinking-cpu";
        displayName = "Kimi K2 Thinking (CPU)";
        model = "unsloth/Kimi-K2-Thinking-GGUF:UD-Q2_K_XL";
        gpu = false;
        resourceRequirements = {
          RAM = 382;
        };
        extraLlamaCppArgs = [
          # Sampling Parameters
          "--temp 1.0"
          "--min-p 0.01"
          # Special flag to show thinking tags
          "--special"
        ];
      }

      # https://docs.unsloth.ai/models/qwen3-next
      {
        name = "qwen3-next-instruct";
        displayName = "Qwen3 Next 80B Instruct";
        model = "unsloth/Qwen3-Next-80B-A3B-Instruct-GGUF:Q4_K_XL";
        gpu = true;
        resourceRequirements = {
          VRAM-1 = 9;
          RAM = 45;
        };
        extraLlamaCppArgs = [
          # Sampling Parameters
          "--temp 0.7"
          "--min-p 0.00"
          "--top-p 0.80"
          "--top-k 20"
          "--presence-penalty 1.0"
          # GPU Settings
          "--n-gpu-layers 999"
          "-ot .ffn_.*_exps.=CPU"
        ];
      }

      # https://docs.unsloth.ai/models/qwen3-next
      {
        name = "qwen3-next-thinking";
        displayName = "Qwen3 Next 80B Thinking";
        model = "unsloth/Qwen3-Next-80B-A3B-Thinking-GGUF:Q4_K_XL";
        gpu = true;
        resourceRequirements = {
          VRAM-1 = 9;
          RAM = 45;
        };
        extraLlamaCppArgs = [
          # Sampling Parameters
          "--temp 0.6"
          "--min-p 0.00"
          "--top-p 0.95"
          "--top-k 20"
          "--presence-penalty 1.0"
          # GPU Settings
          "--n-gpu-layers 999"
          "-ot .ffn_.*_exps.=CPU"
        ];
      }

      # https://docs.unsloth.ai/models/glm-4.6-how-to-run-locally
      {
        name = "glm-4.6";
        displayName = "GLM 4.6";
        model = "unsloth/GLM-4.6-GGUF:Q2_K_XL";
        gpu = true;
        resourceRequirements = {
          VRAM-1 = 24;
          RAM = 124;
        };
        contextSize = 64 * 1024;
        extraLlamaCppArgs = [
          # Sampling Parameters
          "--temp 1.0"
          "--top-p 0.95"
          "--top-k 40"
          # GPU Settings
          "--n-gpu-layers 999"
          "-ot .ffn_.*_exps.=CPU"
        ];
      }

      # https://docs.unsloth.ai/models/glm-4.6-how-to-run-locally
      {
        name = "glm-4.6-cpu";
        displayName = "GLM 4.6 (CPU)";
        model = "unsloth/GLM-4.6-GGUF:Q2_K_XL";
        gpu = false;
        resourceRequirements = {
          RAM = 174;
        };
        extraLlamaCppArgs = [
          # Sampling Parameters
          "--temp 1.0"
          "--top-p 0.95"
          "--top-k 40"
        ];
      }

      # https://docs.unsloth.ai/models/glm-4.6-how-to-run-locally
      {
        name = "glm-4.6v-flash";
        displayName = "GLM 4.6V Flash";
        model = "unsloth/GLM-4.6V-Flash-GGUF:Q4_K_XL";
        gpu = true;
        resourceRequirements = {
          VRAM-1 = 11;
        };
        extraLlamaCppArgs = [
          # Sampling Parameters
          "--temp 0.8"
          "--top-p 0.6"
          "--top-k 2"
          "--repeat_penalty 1.1"
          # GPU Settings
          "--n-gpu-layers 999"
        ];
      }

      {
        name = "glm-4.5-air";
        displayName = "GLM 4.5 Air";
        model = "unsloth/GLM-4.5-Air-GGUF:Q4_K_XL";
        gpu = true;
        resourceRequirements = {
          VRAM-1 = 20;
          RAM = 67;
        };
        extraLlamaCppArgs = [
          # GPU Settings
          "--n-gpu-layers 999"
          "-ot .ffn_.*_exps.=CPU"
        ];
      }

      # https://docs.unsloth.ai/models/ministral-3
      {
        name = "ministral-3b-instruct";
        displayName = "Ministral 3B Instruct";
        model = "unsloth/Ministral-3-3B-Instruct-2512-GGUF:Q4_K_XL";
        gpu = true;
        resourceRequirements = {
          VRAM-1 = 6;
        };
        contextSize = 16 * 1024;
        extraLlamaCppArgs = [
          # Sampling Parameters
          "--temp 0.15"
          # GPU Settings
          "--n-gpu-layers 999"
        ];
      }

      # https://docs.unsloth.ai/models/ministral-3
      {
        name = "ministral-3b-reasoning";
        displayName = "Ministral 3B Reasoning";
        model = "unsloth/Ministral-3-3B-Reasoning-2512-GGUF:Q4_K_XL";
        gpu = true;
        resourceRequirements = {
          VRAM-1 = 6;
        };
        contextSize = 16 * 1024;
        extraLlamaCppArgs = [
          # Sampling Parameters
          "--temp 0.6"
          "--top-p 0.95"
          # GPU Settings
          "--n-gpu-layers 999"
        ];
      }

      # https://docs.unsloth.ai/models/ministral-3
      {
        name = "ministral-14b-instruct";
        displayName = "Ministral 14B Instruct";
        model = "unsloth/Ministral-3-14B-Instruct-2512-GGUF:Q4_K_XL";
        gpu = true;
        resourceRequirements = {
          VRAM-1 = 22;
        };
        contextSize = 128 * 1024;
        extraLlamaCppArgs = [
          # Sampling Parameters
          "--temp 0.15"
          # GPU Settings
          "--n-gpu-layers 999"
        ];
      }

      # https://docs.unsloth.ai/models/ministral-3
      {
        name = "ministral-14b-reasoning";
        displayName = "Ministral 14B Reasoning";
        model = "unsloth/Ministral-3-14B-Reasoning-2512-GGUF:Q4_K_XL";
        gpu = true;
        resourceRequirements = {
          VRAM-1 = 22;
        };
        contextSize = 128 * 1024;
        extraLlamaCppArgs = [
          # Sampling Parameters
          "--temp 0.6"
          "--top-p 0.95"
          # GPU Settings
          "--n-gpu-layers 999"
        ];
      }

      # https://docs.unsloth.ai/models/devstral-2
      {
        name = "devstral-small-2";
        displayName = "Devstral Small 2";
        model = "unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF:UD-Q4_K_XL";
        gpu = true;
        resourceRequirements = {
          VRAM-1 = 22;
        };
        contextSize = 64 * 1024;
        extraLlamaCppArgs = [
          "--mmproj unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF/mmproj-F16.gguf"
          # Sampling Parameters
          "--temp 0.15"
          # GPU Settings
          "--n-gpu-layers 999"
        ];
      }

      # https://docs.unsloth.ai/models/devstral-2
      {
        name = "devstral-2";
        displayName = "Devstral 2";
        model = "unsloth/Devstral-2-123B-Instruct-2512-GGUF:UD-Q2_K_XL";
        gpu = true;
        resourceRequirements = {
          VRAM-1 = 24;
          RAM = 38;
        };
        contextSize = 64 * 1024;
        extraLlamaCppArgs = [
          # Sampling Parameters
          "--temp 0.15"
          # GPU Settings
          "--n-gpu-layers 28"
        ];
      }

      # https://docs.unsloth.ai/models/devstral-2
      {
        name = "devstral-2-cpu";
        displayName = "Devstral 2 (CPU)";
        model = "unsloth/Devstral-2-123B-Instruct-2512-GGUF:UD-Q2_K_XL";
        gpu = false;
        resourceRequirements = {
          RAM = 92;
        };
        extraLlamaCppArgs = [
          # Sampling Parameters
          "--temp 0.15"
        ];
      }
    ]);
  };
in
{
  configStorage = true;
  systemd = {
    extraStorage = [ "comfyui " ];
    macvlan = true;
    tcpPorts = [ 80 8080 8188 ];
    path = [ largeModelProxyPackage pkgs.curl pkgs.docker pkgs.bash ];
    script = { interface, ip, ip6, storagePath, name, ... }: ''
      # Create dedicated Docker network for LMP if it doesn't exist
      if ! docker network inspect ${dockerNetworkName} >/dev/null 2>&1; then
        echo "Creating Docker network: ${dockerNetworkName}"
        docker network create --driver=bridge --subnet=${dockerNetworkPrefix}0/24 --gateway=${dockerNetworkPrefix}1 ${dockerNetworkName}
      fi

      cd ${storagePath name}
      exec large-model-proxy -c ${(pkgs.formats.json { }).generate "config.json" (configuration { hostIp = ip; hostIp6 = ip6; })}
    '';
  };
}
