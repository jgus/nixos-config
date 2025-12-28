{ pkgs, ... }:
{
  configStorage = false;
  docker = {
    image = "cturra/ntp";
    imageFile = pkgs.dockerTools.pullImage
      # nix-shell -p nix-prefetch-docker --run 'nix-prefetch-docker --quiet --image-name cturra/ntp --image-tag latest'
      {
        imageName = "cturra/ntp";
        imageDigest = "sha256:7224d4e7c7833aabbcb7dd70c46c8a8dcccda365314c6db047b9b10403ace3bc";
        hash = "sha256-gJ4Ylre/p2B21fZVF5J2m++KS2J70oQ1YJ3FCk8BU34=";
        finalImageName = "cturra/ntp";
        finalImageTag = "latest";
      };
    ports = [
      "123/udp"
    ];
    environment = {
      NTP_SERVERS = "time.cloudflare.com";
      ENABLE_NTS = "true";
    };
    extraOptions = [
      "--read-only"
      "--tmpfs=/etc/chrony:rw,mode=1750"
      "--tmpfs=/run/chrony:rw,mode=1750"
      "--tmpfs=/var/lib/chrony:rw,mode=1750"
    ];
  };
}
