let
  pw = import ./../.secrets/passwords.nix;
  settings = {
    use_default_settings = true;
    server = {
      base_url = "https://search.gustafson.me";
      port = "8080";
      bind_address = "0.0.0.0";
      secret_key = pw.searxng.secret;
    };
    search = {
      formats = [ "html" "json" ];
    };
  };
in
{ pkgs, ... }:
{
  docker = {
    image = "docker.io/searxng/searxng";
    ports = [
      "8080"
    ];
    configVolume = "/var/cache/searxng";
    volumes = [
      "${(pkgs.formats.yaml { }).generate "settings.yml" settings}:/etc/searxng/settings.yml:ro"
    ];
  };
}
