{ config, pkgs, ... }:

let
  db_image = "mysql:5.7";
  db_admin_image = "phpmyadmin/phpmyadmin";
  swag_image = "lscr.io/linuxserver/swag";
in
{
  imports = [ ./docker.nix ];

  users = {
    groups.www = { gid = 911; };
    users.www = {
      uid = 911;
      isSystemUser = true;
      group = "www";
    };
  };

  system.activationScripts = {
    web-swag-setup.text = ''
      ${pkgs.zfs}/bin/zfs list r/varlib/web_db_data >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create r/varlib/web_db_data
      ${pkgs.zfs}/bin/zfs list r/varlib/web_db_admin_sessions >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create r/varlib/web_db_admin_sessions
      ${pkgs.zfs}/bin/zfs list r/varlib/web_proxy_config >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create r/varlib/web_proxy_config
      ${pkgs.zfs}/bin/zfs list r/varlib/swag_config >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create r/varlib/swag_config
      mkdir -p /var/lib/swag_config/keys
      mkdir -p /var/lib/swag_config/etc/letsencrypt
      ${pkgs.zfs}/bin/zfs list r/varlib/www >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create r/varlib/www
      ${pkgs.zfs}/bin/zfs list r/varlib/dav >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create r/varlib/dav
      mkdir -p /var/lib/dav/tmp
      mkdir -p /var/lib/dav/files
      chown -R www:www /var/lib/dav
    '';
  };

  virtualisation.oci-containers.containers.web-db = {
    image = "${db_image}";
    autoStart = true;
    volumes = [
      "/var/lib/web_db_data:/var/lib/mysql"
    ];
  };

  virtualisation.oci-containers.containers.web-db-admin = {
    image = "${db_admin_image}";
    autoStart = true;
    dependsOn = [ "web-db" ];
    extraOptions = [
      "--link=web-db:db"
    ];
    ports = [
      "8101:80"
    ];
    volumes = [
      "/var/lib/web_db_admin_sessions:/sessions"
    ];
  };

  virtualisation.oci-containers.containers.web-swag = {
    image = "${swag_image}";
    autoStart = true;
    dependsOn = [ "web-db" ];
    extraOptions = [
      "--tmpfs=/config"
      "--tmpfs=/config/www/Photos/cache"
      "--link=web-db:db"
    ];
    environment = {
      URL = "gustafson.me";
      SUBDOMAINS = "www,homeassistant,komga,";
      EXTRA_DOMAINS = "gushome.org,www.gushome.org";
      VALIDATION = "http";
      EMAIL = "joshgstfsn@gmail.com";
      PUID = "${toString config.users.users.www.uid}";
      PGID = "${toString config.users.groups.www.gid}";
      TZ = "${config.time.timeZone}";
    };
    ports = [
      "80:80"
      "443:443"
    ];
    volumes = [
      "/var/lib/swag_config/keys:/config/keys"
      "/var/lib/swag_config/etc/letsencrypt:/config/etc/letsencrypt"
      "/etc/nixos/www/site-confs/default.conf:/config/nginx/site-confs/default.conf"
      "/etc/nixos/www/location-confs:/config/nginx/location-confs"
      "/etc/nixos/www/proxy-confs/homeassistant.subdomain.conf:/config/nginx/proxy-confs/homeassistant.subdomain.conf"
      "/etc/nixos/www/proxy-confs/komga.subdomain.conf:/config/nginx/proxy-confs/komga.subdomain.conf"
      "/var/lib/www:/config/www"
      "/d/photos/Published:/config/www/published:ro"
      "/var/lib/dav:/config/www/dav"
    ];
  };

  systemd = {
    services = {
      web-db-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull ${db_image} | grep "Status: Downloaded"
          then
            systemctl restart docker-web-db
          fi
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        startAt = "hourly";
      };
      web-db-admin-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull ${db_admin_image} | grep "Status: Downloaded"
          then
            systemctl restart docker-web-db-admin
          fi
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        startAt = "hourly";
      };
      web-swag-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull ${swag_image} | grep "Status: Downloaded"
          then
            systemctl restart docker-web-swag
          fi
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        startAt = "hourly";
      };
    };
  };
}
