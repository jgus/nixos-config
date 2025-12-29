{ ... }:
{
  configStorage = true;
  container = {
    pullImage = {
      imageName = "ghcr.io/sillytavern/sillytavern";
      imageDigest = "sha256:e34652eee62e64b23ec15e501293696140141079d8e38515dd9a243e1d0a57d3";
      hash = "sha256-cQy/Ig2riMekcUaE3SJZGWSPz84sy+u/inA8zDnqSH0=";
      finalImageName = "ghcr.io/sillytavern/sillytavern";
      finalImageTag = "latest";
    };
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
