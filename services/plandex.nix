{ lib, ... }:
let
  addresses = import ./../addresses.nix { inherit lib; };
  pw = import ./../.secrets/passwords.nix;
  dbName = "plandex";
  dbUser = "plandex";
  dbPass = pw.plandex.db;
in
[
  {
    name = "plandex-db";
    container = {
      pullImage = import ../images/postgres.nix;
      configVolume = "/var/lib/postgresql/data";
      ports = [
        "5432"
      ];
      environment = {
        POSTGRES_DB = dbName;
        POSTGRES_USER = dbUser;
        POSTGRES_PASSWORD = dbPass;
      };
    };
  }
  {
    name = "plandex";
    container = {
      pullImage = import ../images/plandex.nix;
      dependsOn = [ "plandex-db" ];
      configVolume = "/plandex-server";
      ports = [
        "8099"
      ];
      environment = {
        GOENV = "production";
        DATABASE_URL = "postgres://${dbUser}:${dbPass}@plandex-db:5432/${dbName}?sslmode=disable";
        PORT = "8099";
        PLANDEX_BASE_DIR = "/plandex-server";
        API_HOST = "plandex.${addresses.network.domain}";
        SMTP_HOST = "mail.smtp2go.com";
        SMTP_PORT = "587";
        SMTP_USER = "gustafsonme";
        SMTP_PASSWORD = pw.smtp2go;
        SMTP_FROM = "plandex@gustafson.me";
        NANOGPT_API_KEY = pw.plandex.nanoGptApiKey;
      };
    };
  }
]
