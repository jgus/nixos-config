{ ... }:
{
  configStorage = true;
  container = {
    pullImage = import ../images/sillytavern.nix;
    configVolume = "/home/node/app/config";
    ports = [
      "80"
    ];
    volumes = storagePath: [
      # Plugins directory
      "${storagePath "sillytavern"}/plugins:/home/node/app/plugins"
      # User images/avatars
      "${storagePath "sillytavern"}/public:/home/node/app/public/user"
    ];
  };
}
