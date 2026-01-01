{ ... }:
let
  pw = import ./../.secrets/passwords.nix;
in
[
  {
    name = "journal-db";
    container = {
      pullImage = import ../images/mysql.nix;
      configVolume = "/var/lib/mysql";
    };
  }
  {
    name = "journal";
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
