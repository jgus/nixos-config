{ config, pkgs, ... }:
let
  pw = import ./../.secrets/passwords.nix;
in
[
  {
    name = "joyfulsong-db";
    docker = {
      image = "mysql:9";
      configVolume = "/var/lib/mysql";
      environment = {
        MYSQL_DATABASE = "joyfulsong";
        MYSQL_USER = "joyfulsong";
        MYSQL_PASSWORD = "${pw.joyfulsong.dbPassword}";
        MYSQL_RANDOM_ROOT_PASSWORD = "1";
      };
    };
  }
  {
    name = "joyfulsong";
    docker = {
      image = "wordpress";
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
      };
    };
  }
]
