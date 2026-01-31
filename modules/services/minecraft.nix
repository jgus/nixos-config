let
  user = "minecraft";
  group = "minecraft";
in
{ config, lib, ... }:
{
  homelab.services.minecraft = {
    container = {
      pullImage = import ../../images/minecraft-runner.nix;
      readOnly = false;
      environment = {
        MINECRAFT_UID = toString config.users.users.${user}.uid;
        MINECRAFT_GID = toString config.users.groups.${group}.gid;
      };
      configVolume = "/home/minecraft/config";
      volumes = [
        "${config.sops.secrets."minecraft/ssh/authorized_keys".path}:/ssh-keys-inject/authorized_keys:ro"
        "${config.sops.secrets."minecraft/ssh/ssh_host_ecdsa_key".path}:/ssh-keys-inject/ssh_host_ecdsa_key:ro"
        "${config.sops.secrets."minecraft/ssh/ssh_host_ed25519_key".path}:/ssh-keys-inject/ssh_host_ed25519_key:ro"
        "${config.sops.secrets."minecraft/ssh/ssh_host_rsa_key".path}:/ssh-keys-inject/ssh_host_rsa_key:ro"
        "${../../pubkeys/minecraft}:/ssh-keys-inject:ro"
      ];
    };
  };

  sops = lib.mkIf config.homelab.services.minecraft.enable {
    secrets."minecraft/ssh/authorized_keys" = {
      format = "binary";
      sopsFile = ../../secrets/minecraft/ssh/authorized_keys;
    };
    secrets."minecraft/ssh/ssh_host_ecdsa_key" = {
      format = "binary";
      sopsFile = ../../secrets/minecraft/ssh/ssh_host_ecdsa_key;
    };
    secrets."minecraft/ssh/ssh_host_ed25519_key" = {
      format = "binary";
      sopsFile = ../../secrets/minecraft/ssh/ssh_host_ed25519_key;
    };
    secrets."minecraft/ssh/ssh_host_rsa_key" = {
      format = "binary";
      sopsFile = ../../secrets/minecraft/ssh/ssh_host_rsa_key;
    };
  };
}
