{ addresses, config, ... }:
[
  {
    serviceName = "journal-db";
    container = {
      pullImage = import ../images/mysql.nix;
      configVolume = "/var/lib/mysql";
    };
  }
  {
    serviceName = "journal";
    container = {
      pullImage = import ../images/wordpress.nix;
      dependsOn = [ "journal-db" ];
      configVolume = "/var/www/html";
      ports = [
        "80"
      ];
      environment = {
        WORDPRESS_DB_NAME = "wordpress";
        WORDPRESS_DB_USER = "wordpress";
        WORDPRESS_DB_HOST = "journal-db";
        WORDPRESS_TABLE_PREFIX = "journal_";
        # WORDPRESS_ENVIRONMENT_TYPE = "production";
        WORDPRESS_HOME = "http://journal.${addresses.network.publicDomain}/";
        WORDPRESS_SITEURL = "http://journal.${addresses.network.publicDomain}/";
      };
      environmentFiles = [ config.sops.secrets."journal/env".path ];
    };
    extraConfig = {
      sops.secrets."journal/env" = { };
    };
  }
]
