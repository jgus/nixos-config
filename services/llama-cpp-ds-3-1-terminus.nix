# https://docs.unsloth.ai/models/deepseek-v3.1-how-to-run-locally
{ ... }:
{
  autoStart = false;
  configStorage = false;
  docker = {
    image = "ghcr.io/ggml-org/llama.cpp:server-cuda";
    ports = [
      "8080"
    ];
    volumes = [
      "/storage/llama.cpp:/root/.cache/llama.cpp"
    ];
    extraOptions = [
      "--read-only"
      "--device=nvidia.com/gpu=GPU-8bb9f199-be89-462d-8e68-6ba4fe870ce4"
      "--cap-add"
      "IPC_LOCK"

      # === NUMA Binding ===
      # GPU is on PCIe connected to CPU 2 (NUMA node 1)
      # Bind to that node for optimal memory/PCIe locality
      # On dual E5-2699v3
      # Verify with: numactl --hardware
      "--cpuset-cpus=1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,41,43,45,47,49,51,53,55,57,59,61,63,65,67,69,71"
      # Allow memory from both nodes - kernel prefers local (node 1) first, spills to node 0
      # Trade-off: some remote memory access latency vs OOM
      "--cpuset-mems=0,1"
    ];
    entrypointOptions = [
      # === CPU Threading ===
      # With NUMA binding to one node (36 HT threads), both must be ≤36
      # Generation uses --threads, prompt processing uses --threads-batch
      "--threads"
      "36"
      "--threads-batch"
      "36"

      # === System RAM ===
      "--mlock"
      # "--no-mmap"

      # === Model ===
      "-hf"
      "unsloth/DeepSeek-V3.1-Terminus-GGUF:UD-Q2_K_XL"
      "--jinja"

      # === Sampling Parameters ===
      "--temp"
      "0.6"
      "--top-p"
      "0.95"
      "--min-p"
      "0.01"

      # === CRITICAL: Batch Size for Prompt Processing ===
      # Larger batch size = faster prompt processing (more tokens processed per iteration)
      # 512 -> 2048 should roughly 2-3x prompt processing speed
      # Can go up to 4096 or 8192 if you have the RAM headroom
      "--batch-size"
      "8192"
      # Physical batch size - process this many tokens at once
      "--ubatch-size"
      "2048"

      # === Context Size ===
      "--ctx-size"
      (toString (32 * 1024))

      # === KV Cache Quantization (reduces memory bandwidth) ===
      # Quantize KV cache to reduce memory traffic during attention
      "--cache-type-k"
      "q8_0"
      "--cache-type-v"
      "q8_0"

      # === Flash Attention (faster attention computation) ===
      "--flash-attn"
      "on"

      # === MoE Offloading ===
      "-ot"
      ".ffn_.*_exps.=CPU" # All MoE layers
      # ".ffn_(up|down)_exps.=CPU" # Up & Down MoE layers
      # ".ffn_(up)_exps.=CPU" # Up MoE layers
      "--n-gpu-layers"
      "999"

      # === Prompt Caching (HUGE win for roleplaying with repeated system prompts) ===
      # Cache the processed prompt to disk - reuses KV cache for repeated prefixes
      # This means your system prompt + character definitions only process ONCE
      "--slot-save-path"
      "/root/.cache/llama.cpp/prompt-cache"

      # === Parallel Slots (optional - uncomment if you want multiple concurrent chats) ===
      # "-np"
      # "2"
    ];
  };
}
