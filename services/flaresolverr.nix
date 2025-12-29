{ config, ... }:
{
  configStorage = false;
  container = {
    pullImage = {
      imageName = "ghcr.io/flaresolverr/flaresolverr";
      imageDigest = "sha256:7962759d99d7e125e108e0f5e7f3cdbcd36161776d058d1d9b7153b92ef1af9e";
      hash = "sha256-bmMLEHhZmD5jvdyaXUCCllqYMkLLF2ysZymmTFG/DpQ=";
      finalImageName = "ghcr.io/flaresolverr/flaresolverr";
      finalImageTag = "latest";
    };
    ports = [
      "8191"
    ];
    environment = {
      TZ = config.time.timeZone;
    };
  };
}
