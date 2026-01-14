{ addresses, myLib, ... }:
let
  configuration = {
    metadata_dir = "/var/lib/garage/meta";
    data_dir = "/var/lib/garage/data";
    db_engine = "sqlite";

    replication_factor = 1;

    rpc_bind_addr = "[::]:3901";
    rpc_public_addr = "${addresses.nameToIp.garage}:3901";
    rpc_secret = "e1464e7a73d8642c5f8abe0e7928262e56654bed1eb6aed5c038d9a6ade61ad2"; # openssl rand -hex 32

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
      admin_token = "EnLZ8Bjmk6Qtzid9AlixUZ/FCT1/INyWyMJh3jlASXk="; # openssl rand -base64 32
      metrics_token = "aL+UfvF2d+ufInYxJg9Dks0HXNK6VNck+uyXc88E3Ak="; # openssl rand -base64 32
    };
  };
in
{
  configStorage = false;
  container = {
    pullImage = import ../images/garage.nix;
    readOnly = true;
    volumes = [
      "${myLib.prettyToml configuration}:/etc/garage.toml:ro"
      "/storage/garage/meta:/var/lib/garage/meta"
      "/storage/garage/data:/var/lib/garage/data"
    ];
  };
}
