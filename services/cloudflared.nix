{ config, ... }:
{
  configStorage = false;
  container = {
    pullImage = import ../images/cloudflared.nix;
    entrypointOptions = [
      "tunnel"
      "--no-autoupdate"
      "run"
    ];
    environmentFiles = [
      config.sops.secrets."cloudflared/env".path
    ];
  };
  extraConfig = {
    sops.secrets."cloudflared/env" = { };
  };
}
