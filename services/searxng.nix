let
  pw = import ./../.secrets/passwords.nix;
in
{ config, ... }:
{
  docker = {
    image = "docker.io/searxng/searxng";
    environment = {
      # PUID = toString config.users.users.${user}.uid;
      # PGID = toString config.users.groups.${group}.gid;
      # TZ = config.time.timeZone;
      # USER = "josh";
      # PASS = pw.transmission;
      SEARXNG_BASE_URL = "http://searxng.home.gustafson.me:8080";
      SEARXNG_PORT = "8080";
      SEARXNG_BIND_ADDRESS = "0.0.0.0";
      SEARXNG_SECRET = pw.searxng.secret;
    };
    ports = [
      "8080"
    ];
    configVolume = "/var/cache/searxng";
  };
}
