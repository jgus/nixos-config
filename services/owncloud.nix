{ lib, ... }:
let
  addresses = import ./../addresses.nix { inherit lib; };
  pw = import ./../.secrets/passwords.nix;
  adminUser = "admin";
  adminPass = pw.owncloud.admin;
  dbName = "owncloud";
  dbUser = "owncloud";
  dbPass = pw.owncloud.db;
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
        OWNCLOUD_DB_PASSWORD = dbPass;
        OWNCLOUD_DB_HOST = "owncloud-db.${addresses.network.domain}";
        OWNCLOUD_ADMIN_USERNAME = adminUser;
        OWNCLOUD_ADMIN_PASSWORD = adminPass;
        OWNCLOUD_MYSQL_UTF8MB4 = "true";
        OWNCLOUD_REDIS_ENABLED = "true";
        OWNCLOUD_REDIS_HOST = "owncloud-redis.${addresses.network.domain}";
        ADMIN_USERNAME = adminUser;
        ADMIN_PASSWORD = adminPass;
        HTTP_PORT = "8080";
      };
      ports = [ "8080" ];
      volumes = [ "/storage/owncloud:/mnt/data" ];
    };
  }
  {
    name = "owncloud-db";
    container = {
      readOnly = false;
      pullImage = import ../images/mariadb.nix;
      environment = {
        MYSQL_ROOT_PASSWORD = dbPass;
        MYSQL_USER = dbUser;
        MYSQL_PASSWORD = dbPass;
        MYSQL_DATABASE = dbName;
        MARIADB_AUTO_UPGRADE = "1";
      };
      configVolume = "/var/lib/mysql";
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
