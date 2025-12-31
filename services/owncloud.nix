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
      pullImage = {
        imageName = "owncloud/server";
        imageDigest = "sha256:62c93574d2bd0f98d17ac1a541f703653822e4572a628dcf993a8e65b2400e97";
        hash = "sha256-ftE9szjmZzqcMZtk46qWfWwAPEI3Ef88BbT9glrcV4U=";
        finalImageName = "owncloud/server";
        finalImageTag = "latest";
      };
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
      pullImage = {
        imageName = "mariadb";
        imageDigest = "sha256:8763a63f00ec980d913c04bf84f7fd5f60aa11ac9033f36d1a77921c065a5988";
        hash = "sha256-Mo6hqQxl4/pLVJjnDZLqX67MdRah0MFiDvOHabl85oo=";
        finalImageName = "mariadb";
        finalImageTag = "10";
      };
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
      pullImage = {
        imageName = "redis";
        imageDigest = "sha256:b0637889625b89ff449612d5729da2b99adafeda9b2c16faa5428f2dbd310685";
        hash = "sha256-MJGq50IuW4Q5mzooCaSmyseVnPhlsAv2RdFZnYb+yss=";
        finalImageName = "redis";
        finalImageTag = "6";
      };
      configVolume = "/data";
    };
  }
]
