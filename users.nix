{ config, pkgs, lib, ... }:
let
  container = import ./container.nix { inherit pkgs lib; };
in
{
  users = {
    mutableUsers = false;

    groups = {
      users.gid = 100;
      media.gid = 193;
      home-assistant.gid = 200;
      www.gid = 911;
      mosquitto.gid = 1883;
      minecraft.gid = 2000;
    };

    users = {
      root = {
        hashedPasswordFile = config.sops.secrets."users/josh".path;
        openssh.authorizedKeys.keyFiles = [ ./pubkeys/josh-ed25519 ./pubkeys/josh-rsa ];
      };

      media = {
        uid = 193;
        isSystemUser = true;
        group = "media";
      };

      home-assistant = {
        uid = 200;
        isSystemUser = true;
        group = "home-assistant";
      };

      www = {
        uid = 911;
        isSystemUser = true;
        group = "www";
      };

      mosquitto = {
        uid = 1883;
        isSystemUser = true;
        group = "mosquitto";
      };

      gustafson = {
        uid = 1000;
        isNormalUser = true;
      };

      josh = {
        uid = 1001;
        isNormalUser = true;
        extraGroups = [ "wheel" "www" container.group "libvirtd" "davfs2" ];
        hashedPasswordFile = config.sops.secrets."users/josh".path;
        openssh.authorizedKeys.keyFiles = [ ./pubkeys/josh-ed25519 ./pubkeys/josh-rsa ];
      };

      nathaniel = {
        uid = 1023;
        isNormalUser = true;
      };

      minecraft = {
        uid = 2000;
        isSystemUser = true;
        group = "minecraft";
      };
    };
  };

  sops.secrets = {
    "users/root" = { neededForUsers = true; };
    "users/josh" = { neededForUsers = true; };
  };
}
