{ config, lib, ... }:
{
  homelab.services.cloudflared = {
    configStorage = false;
    container = {
      pullImage = import ../../images/cloudflared.nix;
      entrypointOptions = [
        "tunnel"
        "--no-autoupdate"
        "run"
      ];
      environmentFiles = [
        config.sops.secrets."cloudflared/env".path
      ];
    };
  };

  sops = lib.mkIf config.homelab.services.cloudflared.enable {
    secrets."cloudflared/env" = { };
  };
}
