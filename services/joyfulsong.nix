{ ... }:
let
  pw = import ./../.secrets/passwords.nix;
in
[
  {
    name = "joyfulsong-db";
    container = {
      pullImage = {
        imageName = "mariadb";
        imageDigest = "sha256:e1bcd6f85781f4a875abefb11c4166c1d79e4237c23de597bf0df81fec225b40";
        hash = "sha256-tPm0XwIe/rM3+gJkQbzpj+/emE8j1HNqIg1yjb37+TI=";
        finalImageName = "mariadb";
        finalImageTag = "latest";
      };
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
      pullImage = {
        imageName = "wordpress";
        imageDigest = "sha256:39ec4f8802d6c5e15b655766fe86f7f83ded0fc92e58d0aa4e9706bf215a4ad3";
        hash = "sha256-eeEc9jq3PkKvumau29nO9ZbA3A8KiR3tkpWzgRbl2t0=";
        finalImageName = "wordpress";
        finalImageTag = "php8.3-apache";
      };
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
