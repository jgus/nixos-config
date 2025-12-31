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
  container = {
    pullImage = {
      imageName = "docker.io/searxng/searxng";
      imageDigest = "sha256:1ad4159e74903f8870e3464df701b800a75bd2854f5d11b44ce09ee297f3c158";
      hash = "sha256-4NThBCZQyVU29/DPmhXbhsEWqdLw9BdhMuPxL4Ksse4=";
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
