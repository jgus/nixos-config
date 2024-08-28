{ ... }:
{
  configStorage = false;
  docker = {
    image = "cturra/ntp";
    ports = [
      "123/udp"
    ];
    extraOptions = [
      "--read-only"
      "--tmpfs=/etc/chrony:rw,mode=1750"
      "--tmpfs=/run/chrony:rw,mode=1750"
      "--tmpfs=/var/lib/chrony:rw,mode=1750"
    ];
  };
}
