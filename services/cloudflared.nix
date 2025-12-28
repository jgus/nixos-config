{ ... }:
{
  configStorage = false;
  docker = {
    pullImage =
      # nix-shell -p nix-prefetch-docker --run 'nix-prefetch-docker --quiet --image-name cloudflare/cloudflared --image-tag latest'
      {
        imageName = "cloudflare/cloudflared";
        imageDigest = "sha256:89ee50efb1e9cb2ae30281a8a404fed95eb8f02f0a972617526f8c5b417acae2";
        hash = "sha256-ka5U3ixEo9GGjlq2tlwW6Gd4hNOmYM+Srwgd9YOFyig=";
        finalImageName = "cloudflare/cloudflared";
        finalImageTag = "latest";
      };
    extraOptions = [
      "--read-only"
    ];
    entrypointOptions = [
      "tunnel"
      "--no-autoupdate"
      "run"
      "--token"
      "eyJhIjoiNDg2M2FkMjU2YjEzNjdhNTU5OGI2YjMwMzA2MTMzZDgiLCJ0IjoiYmQ2NzFhMzYtMGNjOC00OTJiLWE4YjYtZTcwYWUwODBkMDdlIiwicyI6IlptTTRNalkxWVdFdE16WTNPUzAwTmpnekxUaGtZemt0WWpNMk1tUm1PVGRrWW1aayJ9"
    ];
  };
}
