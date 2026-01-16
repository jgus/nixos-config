{ config, ... }:
[
  {
    name = "joyfulsong-db";
    container = {
      pullImage = import ../images/mariadb.nix;
      configVolume = "/var/lib/mysql";
      environment = {
        MARIADB_DATABASE = "joyfulsong";
        MARIADB_USER = "joyfulsong";
        MARIADB_RANDOM_ROOT_PASSWORD = "1";
      };
      environmentFiles = [ config.sops.secrets."joyfulsong/db-env".path ];
    };
    extraConfig = {
      sops.secrets."joyfulsong/db-env" = { };
    };
  }
  {
    name = "joyfulsong";
    container = {
      pullImage = import ../images/wordpress.nix;
      dependsOn = [ "joyfulsong-db" ];
      configVolume = "/var/www/html";
      ports = [
        "80"
      ];
      environment = {
        WORDPRESS_DB_NAME = "joyfulsong";
        WORDPRESS_DB_USER = "joyfulsong";
        WORDPRESS_DB_HOST = "joyfulsong-db";
        # WORDPRESS_ENVIRONMENT_TYPE = "production";
        WORDPRESS_HOME = "http://joyfulsong.org/";
        WORDPRESS_SITEURL = "http://joyfulsong.org/";
      };
      environmentFiles = [ config.sops.secrets."joyfulsong/env".path ];
    };
    extraConfig = {
      sops.secrets."joyfulsong/env" = { };
    };
  }
]
