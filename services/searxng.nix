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
    pullImage =
      # nix-shell -p nix-prefetch-docker --run 'nix-prefetch-docker --quiet --image-name docker.io/searxng/searxng --image-tag latest'
      {
        imageName = "docker.io/searxng/searxng";
        imageDigest = "sha256:8d98d5c1b678714c3b20dacfab5ea5e3b67f79e50df6d5dbc92ed4f0a964ccbd";
        hash = "sha256-FYn1E9WUVdrjboXP4rTdCzAcskMW+NcnAbJn6dYvhH0=";
        finalImageName = "docker.io/searxng/searxng";
        finalImageTag = "latest";
      };
    ports = [
      "8080"
    ];
    configVolume = "/var/cache/searxng";
    volumes = [
      "${(pkgs.formats.yaml { }).generate "settings.yml" settings}:/etc/searxng/settings.yml:ro"
    ];
  };
}
