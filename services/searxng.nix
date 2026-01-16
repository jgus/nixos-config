with builtins;
{ addresses, config, myLib, ... }:
let
  settings = {
    use_default_settings = true;
    server = {
      base_url = "https://search.${addresses.network.publicDomain}";
      port = "8080";
      bind_address = "[::]";
      secret_key = config.sops.placeholder.searxng;
    };
    search = {
      formats = [ "html" "json" ];
    };
  };
in
{
  container = {
    pullImage = import ../images/searxng.nix;
    ports = [
      "8080"
    ];
    configVolume = "/var/cache/searxng";
    volumes = [
      "${config.sops.templates."searxng/config.yml".path}:/etc/searxng/settings.yml:ro"
    ];
  };
  extraConfig = {
    sops = {
      secrets.searxng = { };
      templates."searxng/config.yml".content = readFile (myLib.prettyYaml settings);
    };
  };
}
