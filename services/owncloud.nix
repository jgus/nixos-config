{ config, lib, ... }:
let
  addresses = import ./../addresses.nix { inherit lib; };
  adminUser = "admin";
  dbName = "owncloud";
  dbUser = "owncloud";
in
[
  {
    name = "owncloud";
    configStorage = false;
    requires = [ "storage-owncloud.mount" ];
    container = {
      readOnly = false;
      pullImage = import ../images/owncloud.nix;
      dependsOn = [ "owncloud-db" "owncloud-redis" ];
      environment = {
        OWNCLOUD_VERSION = "10.15";
        OWNCLOUD_DOMAIN = "drive.gustafson.me";
        OWNCLOUD_TRUSTED_DOMAINS = "drive.gustafson.me,owncloud.${addresses.network.domain}";
        OWNCLOUD_DB_TYPE = "mysql";
        OWNCLOUD_DB_NAME = dbName;
        OWNCLOUD_DB_USERNAME = dbUser;
        OWNCLOUD_DB_HOST = "owncloud-db.${addresses.network.domain}";
        OWNCLOUD_ADMIN_USERNAME = adminUser;
        OWNCLOUD_MYSQL_UTF8MB4 = "true";
        OWNCLOUD_REDIS_ENABLED = "true";
        OWNCLOUD_REDIS_HOST = "owncloud-redis.${addresses.network.domain}";
        ADMIN_USERNAME = adminUser;
        HTTP_PORT = "8080";
      };
      environmentFiles = [
        config.sops.templates."owncloud/env".path
      ];
      ports = [ "8080" ];
      volumes = [ "/storage/owncloud:/mnt/data" ];
    };
    extraConfig = {
      sops = {
        secrets."owncloud/admin" = { };
        secrets."owncloud/db" = { };
        templates."owncloud/env".content = ''
          OWNCLOUD_DB_PASSWORD=${config.sops.placeholder."owncloud/db"}
          OWNCLOUD_ADMIN_PASSWORD=${config.sops.placeholder."owncloud/admin"}
          ADMIN_PASSWORD=${config.sops.placeholder."owncloud/admin"}
        '';
      };
    };
  }
  {
    name = "owncloud-db";
    container = {
      readOnly = false;
      pullImage = import ../images/mariadb.nix;
      environment = {
        MYSQL_USER = dbUser;
        MYSQL_DATABASE = dbName;
        MARIADB_AUTO_UPGRADE = "1";
      };
      environmentFiles = [
        config.sops.templates."owncloud-db/env".path
      ];
      configVolume = "/var/lib/mysql";
    };
    extraConfig = {
      sops = {
        secrets."owncloud/db" = { };
        templates."owncloud-db/env".content = ''
          MYSQL_ROOT_PASSWORD=${config.sops.placeholder."owncloud/db"}
          MYSQL_PASSWORD=${config.sops.placeholder."owncloud/db"}
        '';
      };
    };
  }
  {
    name = "owncloud-redis";
    container = {
      readOnly = false;
      pullImage = import ../images/redis.nix;
      configVolume = "/data";
    };
  }
]
