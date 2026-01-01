let
  user = "minecraft";
  group = "minecraft";
in
{ config, ... }:
{
  container = {
    pullImage = import ../images/minecraft-runner.nix;
    configVolume = "/home/minecraft/config";
    volumes = [
      "${../.secrets/minecraft}:/ssh-keys-inject"
    ];
    environment = {
      MINECRAFT_UID = toString config.users.users.${user}.uid;
      MINECRAFT_GID = toString config.users.groups.${group}.gid;
    };
  };
}
