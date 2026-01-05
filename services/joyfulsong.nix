{ ... }:
let
  pw = import ./../.secrets/passwords.nix;
in
[
  {
    name = "joyfulsong-db";
    container = {
      readOnly = false;
      pullImage = import ../images/mariadb.nix;
      configVolume = "/var/lib/mysql";
      environment = {
        MARIADB_DATABASE = "joyfulsong";
        MARIADB_USER = "joyfulsong";
        MARIADB_PASSWORD = "${pw.joyfulsong.dbPassword}";
        MARIADB_RANDOM_ROOT_PASSWORD = "1";
      };
    };
  }
  {
    name = "joyfulsong";
    container = {
      readOnly = false;
      pullImage = import ../images/wordpress.nix;
      dependsOn = [ "joyfulsong-db" ];
      configVolume = "/var/www/html";
      ports = [
        "80"
      ];
      environment = {
        WORDPRESS_DB_NAME = "joyfulsong";
        WORDPRESS_DB_USER = "joyfulsong";
        WORDPRESS_DB_PASSWORD = "${pw.joyfulsong.dbPassword}";
        WORDPRESS_DB_HOST = "joyfulsong-db";
        WORDPRESS_AUTH_KEY = pw.joyfulsong.AUTH_KEY;
        WORDPRESS_SECURE_AUTH_KEY = pw.joyfulsong.SECURE_AUTH_KEY;
        WORDPRESS_LOGGED_IN_KEY = pw.joyfulsong.LOGGED_IN_KEY;
        WORDPRESS_NONCE_KEY = pw.joyfulsong.NONCE_KEY;
        WORDPRESS_AUTH_SALT = pw.joyfulsong.AUTH_SALT;
        WORDPRESS_SECURE_AUTH_SALT = pw.joyfulsong.SECURE_AUTH_SALT;
        WORDPRESS_LOGGED_IN_SALT = pw.joyfulsong.LOGGED_IN_SALT;
        WORDPRESS_NONCE_SALT = pw.joyfulsong.NONCE_SALT;
        # WORDPRESS_ENVIRONMENT_TYPE = "production";
        WORDPRESS_HOME = "http://joyfulsong.org/";
        WORDPRESS_SITEURL = "http://joyfulsong.org/";
      };
    };
  }
]
