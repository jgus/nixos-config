{ config, lib, ... }:
{
  homelab.services = {
    joyfulsong-db = {
      container = {
        pullImage = import ../../images/mariadb.nix;
        environment = {
          MARIADB_DATABASE = "joyfulsong";
          MARIADB_USER = "joyfulsong";
          MARIADB_RANDOM_ROOT_PASSWORD = "1";
        };
        environmentFiles = [ config.sops.secrets."joyfulsong/db-env".path ];
        configVolume = "/var/lib/mysql";
      };
    };
    joyfulsong = {
      container = {
        pullImage = import ../../images/wordpress.nix;
        dependsOn = [ "joyfulsong-db" ];
        environment = {
          WORDPRESS_DB_NAME = "joyfulsong";
          WORDPRESS_DB_USER = "joyfulsong";
          WORDPRESS_DB_HOST = "joyfulsong-db";
          # WORDPRESS_ENVIRONMENT_TYPE = "production";
          WORDPRESS_HOME = "http://joyfulsong.org/";
          WORDPRESS_SITEURL = "http://joyfulsong.org/";
        };
        environmentFiles = [ config.sops.secrets."joyfulsong/env".path ];
        configVolume = "/var/www/html";
        ports = [
          "80"
        ];
      };
    };
  };

  sops = lib.homelab.recursiveUpdates [
    (lib.mkIf config.homelab.services.joyfulsong-db.enable {
      secrets."joyfulsong/db-env" = { };
    })
    (lib.mkIf config.homelab.services.joyfulsong.enable {
      secrets."joyfulsong/env" = { };
    })
  ];
}
