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
      "/d/llama.cpp:/root/.cache/llama.cpp"
    ];
    extraOptions = [
      "--read-only"
      "--device=nvidia.com/gpu=GPU-8bb9f199-be89-462d-8e68-6ba4fe870ce4"
    ];
    entrypointOptions = [
      "--threads"
      "72"
      # "-np"
      # "4"
      "-hf"
      "unsloth/DeepSeek-V3.1-Terminus-GGUF:UD-Q2_K_XL"
      "--jinja"
      "--temp"
      "0.6"
      "--top-p"
      "0.95"
      "--min-p"
      "0.01"
      "--batch-size"
      "512"
      "--ctx-size"
      (toString (32 * 1024))
      "-ot"
      ".ffn_.*_exps.=CPU"
    ];
  };
}
