{ addresses, config, lib, ... }:
let
  adminUser = "admin";
  dbName = "owncloud";
  dbUser = "owncloud";
in
{
  homelab.services.owncloud = {
    configStorage = false;
    requires = [ "storage-owncloud.mount" ];
    container = {
      pullImage = import ../../images/owncloud.nix;
      readOnly = false;
      dependsOn = [ "owncloud-db" "owncloud-redis" ];
      environment = {
        OWNCLOUD_VERSION = "10.15";
        OWNCLOUD_DOMAIN = "drive.${addresses.network.publicDomain}";
        OWNCLOUD_TRUSTED_DOMAINS = "drive.${addresses.network.publicDomain},owncloud.${addresses.network.domain}";
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
        OWNCLOUD_SKIP_CHOWN = "true";
        OWNCLOUD_SKIP_CHMOD = "true";
      };
      environmentFiles = [
        config.sops.templates."owncloud/env".path
      ];
      volumes = [ "/storage/owncloud:/mnt/data" ];
      ports = [ "8080" ];
    };
  };
  homelab.services.owncloud-db = {
    container = {
      pullImage = import ../../images/mariadb.nix;
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
  };
  homelab.services.owncloud-redis = {
    container = {
      pullImage = import ../../images/redis.nix;
      configVolume = "/data";
    };
  };

  sops = lib.homelab.recursiveUpdates [
    (lib.mkIf config.homelab.services.owncloud.enable {
      secrets."owncloud/admin" = { };
      secrets."owncloud/db" = { };
      templates."owncloud/env".content = ''
        OWNCLOUD_DB_PASSWORD=${config.sops.placeholder."owncloud/db"}
        OWNCLOUD_ADMIN_PASSWORD=${config.sops.placeholder."owncloud/admin"}
        ADMIN_PASSWORD=${config.sops.placeholder."owncloud/admin"}
      '';
    })
    (lib.mkIf config.homelab.services.owncloud-db.enable {
      secrets."owncloud/db" = { };
      templates."owncloud-db/env".content = ''
        MYSQL_ROOT_PASSWORD=${config.sops.placeholder."owncloud/db"}
        MYSQL_PASSWORD=${config.sops.placeholder."owncloud/db"}
      '';
    })
  ];
}
