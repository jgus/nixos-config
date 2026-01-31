with builtins;
{ addresses, config, lib, ... }:
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
  homelab.services.searxng = {
    container = {
      pullImage = import ../../images/searxng.nix;
      configVolume = "/var/cache/searxng";
      volumes = [
        "${config.sops.templates."searxng/config.yml".path}:/etc/searxng/settings.yml:ro"
      ];
      ports = [
        "8080"
      ];
    };
  };

  sops = lib.mkIf config.homelab.services.searxng.enable {
    secrets.searxng = { };
    templates."searxng/config.yml".content = readFile (lib.homelab.prettyYaml settings);
  };
}
