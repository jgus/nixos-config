{ config, pkgs, ... }:
[
  {
    name = "web-db-admin";
    configStorage = false;
    extraStorage = [ "web_db_admin_sessions" ];
    requires = [ "var-lib-web_db_admin_sessions.mount" ];
    docker = {
      image = "phpmyadmin/phpmyadmin";
      ports = [ "80" ];
      volumes = storagePath: [ "${storagePath "web_db_admin_sessions"}:/sessions" ];
    };
  }
  {
    name = "web-db";
    configStorage = false;
    extraStorage = [ "web_db_data" ];
    requires = [ "var-lib-web_db_data.mount" ];
    docker = {
      image = "mysql:5.7";
      volumes = storagePath: [ "${storagePath "web_db_data"}:/var/lib/mysql" ];
    };
  }
  {
    name = "web-swag";
    configStorage = false;
    extraStorage = [ "www" "dav" "swag_config" ];
    requires = [ "var-lib-swag_config.mount" "var-lib-www.mount" "var-lib-dav.mount" "storage-photos.mount" ];
    docker = {
      image = "lscr.io/linuxserver/swag";
      dependsOn = [ "web-db" ];
      extraOptions = [
        "--tmpfs=/config"
        "--tmpfs=/config/www/Photos/cache"
      ];
      environment = {
        URL = "gustafson.me";
        SUBDOMAINS = "www,homeassistant,komga,";
        EXTRA_DOMAINS = "gushome.org,www.gushome.org";
        VALIDATION = "http";
        EMAIL = "joshgstfsn@gmail.com";
        PUID = toString config.users.users.www.uid;
        PGID = toString config.users.groups.www.gid;
        TZ = config.time.timeZone;
      };
      ports = [
        "80"
        "443"
      ];
      volumes = storagePath: [
        "${./www/site-confs/default.conf}:/config/nginx/site-confs/default.conf"
        "${./www/location-confs}:/config/nginx/location-confs"
        "${./www/proxy-confs/homeassistant.subdomain.conf}:/config/nginx/proxy-confs/homeassistant.subdomain.conf"
        "${./www/proxy-confs/komga.subdomain.conf}:/config/nginx/proxy-confs/komga.subdomain.conf"
        "${storagePath "swag_config"}/keys:/config/keys"
        "${storagePath "swag_config"}/etc/letsencrypt:/config/etc/letsencrypt"
        "${storagePath "www"}:/config/www"
        "${storagePath "dav"}:/config/www/dav"
        "/storage/photos/Published:/config/www/published:ro"
      ];
    };
  }
]