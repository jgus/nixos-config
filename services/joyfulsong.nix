{ pkgs, ... }:
let
  pw = import ./../.secrets/passwords.nix;
in
[
  {
    name = "joyfulsong-db";
    docker = {
      image = "mariadb";
      imageFile = pkgs.dockerTools.pullImage
        # nix-shell -p nix-prefetch-docker --run 'nix-prefetch-docker --quiet --image-name mariadb --image-tag latest'
        {
          imageName = "mariadb";
          imageDigest = "sha256:e1bcd6f8578111dfdafc78fd2adf2d15a54d4f185611d5f7b6b75cf967f1c1b1";
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
    docker = {
      image = "wordpress:php8.3-apache";
      imageFile = pkgs.dockerTools.pullImage
        # nix-shell -p nix-prefetch-docker --run 'nix-prefetch-docker --quiet --image-name wordpress --image-tag php8.3-apache'
        {
          imageName = "wordpress";
          imageDigest = "sha256:3655391d4ecab1fcdbf80a83fe2b9f473ccb90797dc3ea9739ef6ad63b146bad";
          hash = "sha256-ZzTB+yUJ9SdI4VLTbXHZEdYGAPuRfplWeDIs6qp6eVk=";
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
