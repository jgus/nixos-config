{ ... }:
{
  configStorage = false;
  docker = {
    image = "cloudflare/cloudflared:latest";
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
