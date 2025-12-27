let
  user = "minecraft";
  group = "minecraft";
in
{ config, ... }:
{
  docker = {
    image = "ghcr.io/jgus/minecraft-runner:1.0.0-java21";
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
