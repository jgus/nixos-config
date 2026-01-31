with builtins;
{ addresses, config, lib, ... }:
let
  configuration = {
    metadata_dir = "/var/lib/garage/meta";
    data_dir = "/var/lib/garage/data";
    db_engine = "sqlite";

    replication_factor = 1;

    rpc_bind_addr = "[::]:3901";
    rpc_public_addr = "${lib.homelab.nameToIp.garage}:3901";
    rpc_secret = config.sops.placeholder."garage/rpc_secret";

    s3_api = {
      s3_region = "garage";
      api_bind_addr = "[::]:3900";
      root_domain = ".s3.garage.${addresses.network.domain}";
    };

    s3_web = {
      bind_addr = "[::]:3902";
      root_domain = ".web.garage.${addresses.network.domain}";
      index = "index.html";
    };

    k2v_api = {
      api_bind_addr = "[::]:3904";
    };

    admin = {
      api_bind_addr = "[::]:3903";
      admin_token = config.sops.placeholder."garage/admin_token";
      metrics_token = config.sops.placeholder."garage/metrics_token";
    };
  };
in
{
  homelab.services.garage = {
    configStorage = false;
    container = {
      pullImage = import ../../images/garage.nix;
      volumes = [
        "${config.sops.templates."garage/garage.toml".path}:/etc/garage.toml:ro"
        "/storage/garage/meta:/var/lib/garage/meta"
        "/storage/garage/data:/var/lib/garage/data"
      ];
    };
  };

  sops = lib.mkIf config.homelab.services.garage.enable {
    secrets = {
      "garage/rpc_secret" = { };
      "garage/admin_token" = { };
      "garage/metrics_token" = { };
    };
    templates."garage/garage.toml".content = readFile (lib.homelab.prettyToml configuration);
  };
}
