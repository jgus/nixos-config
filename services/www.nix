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
        SUBDOMAINS = "www,homeassistant,komga,drive,office,n-kvm,";
        # EXTRA_DOMAINS = "gushome.org,www.gushome.org";
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
        "/etc/nixos/services/www/site-confs/default.conf:/config/nginx/site-confs/default.conf"
        "/etc/nixos/services/www/location-confs:/config/nginx/location-confs"
      ]
      ++
      (map (i: "/etc/nixos/services/www/proxy-confs/${i}.subdomain.conf:/config/nginx/proxy-confs/${i}.subdomain.conf") [ "homeassistant" "komga" "owncloud" "onlyoffice" "n-kvm" ])
      ++
      [
        "${storagePath "swag_config"}/keys:/config/keys"
        "${storagePath "swag_config"}/etc/letsencrypt:/config/etc/letsencrypt"
        "${storagePath "www"}:/config/www"
        "${storagePath "dav"}:/config/www/dav"
      ];
    };
    extraConfig = {
      systemd.mounts = [{
        what = "/storage/photos/Published";
        where = "/service/www/published";
        options = "rbind,uid=${toString config.users.users.www.uid},gid=${toString config.users.groups.www.gid},ro";
      }];
    };
  }
]
