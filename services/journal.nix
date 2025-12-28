{ ... }:
let
  pw = import ./../.secrets/passwords.nix;
in
[
  {
    name = "journal-db";
    docker = {
      pullImage =
        # nix-shell -p nix-prefetch-docker --run 'nix-prefetch-docker --quiet --image-name mysql --image-tag 5.7'
        {
          imageName = "mysql";
          imageDigest = "sha256:4bc6bc963e6d8443453676cae56536f4b8156d78bae03c0145cbe47c2aad73bb";
          hash = "sha256-GeeN1dtcTE9Bi08IjGG6RuEPLOieewK3SPzvlhK+6sQ=";
          finalImageName = "mysql";
          finalImageTag = "5.7";
        };
      configVolume = "/var/lib/mysql";
    };
  }
  {
    name = "journal";
    docker = {
      pullImage =
        # nix-shell -p nix-prefetch-docker --run 'nix-prefetch-docker --quiet --image-name wordpress --image-tag php8.3-apache'
        {
          imageName = "wordpress";
          imageDigest = "sha256:3655391d4ecab1fcdbf80a83fe2b9f473ccb90797dc3ea9739ef6ad63b146bad";
          hash = "sha256-ZzTB+yUJ9SdI4VLTbXHZEdYGAPuRfplWeDIs6qp6eVk=";
          finalImageName = "wordpress";
          finalImageTag = "php8.3-apache";
        };
      dependsOn = [ "journal-db" ];
      configVolume = "/var/www/html";
      ports = [
        "80"
      ];
      environment = {
        WORDPRESS_DB_NAME = "wordpress";
        WORDPRESS_DB_USER = "wordpress";
        WORDPRESS_DB_PASSWORD = "${pw.journal.dbPassword}";
        WORDPRESS_DB_HOST = "journal-db";
        WORDPRESS_AUTH_KEY = pw.journal.AUTH_KEY;
        WORDPRESS_SECURE_AUTH_KEY = pw.journal.SECURE_AUTH_KEY;
        WORDPRESS_LOGGED_IN_KEY = pw.journal.LOGGED_IN_KEY;
        WORDPRESS_NONCE_KEY = pw.journal.NONCE_KEY;
        WORDPRESS_AUTH_SALT = pw.journal.AUTH_SALT;
        WORDPRESS_SECURE_AUTH_SALT = pw.journal.SECURE_AUTH_SALT;
        WORDPRESS_LOGGED_IN_SALT = pw.journal.LOGGED_IN_SALT;
        WORDPRESS_NONCE_SALT = pw.journal.NONCE_SALT;
        WORDPRESS_TABLE_PREFIX = "journal_";
        # WORDPRESS_ENVIRONMENT_TYPE = "production";
        WORDPRESS_HOME = "http://journal.gustafson.me/";
        WORDPRESS_SITEURL = "http://journal.gustafson.me/";
      };
    };
  }
]
