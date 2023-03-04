{ config, pkgs, ... }:

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

  systemd = {
    services = {
      web-db = {
        enable = true;
        description = "Web DB";
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.docker ];
        script = ''
          docker container stop web-db >/dev/null 2>&1 || true ; \
          docker run --rm --name web-db \
            -v /var/lib/web_db_data:/var/lib/mysql \
            mysql:5.7
          '';
      };
      web-db-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull mysql:5.7 | grep "Status: Downloaded"
          then
            systemctl restart web-db
          fi
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        startAt = "hourly";
      };
      web-db-admin = {
        enable = false;
        description = "Web DB Admin";
        wantedBy = [ "multi-user.target" ];
        requires = [ "web-db.service" ];
        path = [ pkgs.docker ];
        script = ''
          docker container stop web-db-admin >/dev/null 2>&1 || true ; \
          docker run --rm --name web-db-admin \
            -v /var/lib/web_db_admin_sessions:/sessions \
            --link web-db:db \
            -p 8101:80 \
            phpmyadmin/phpmyadmin
          '';
      };
      web-db-admin-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull phpmyadmin/phpmyadmin | grep "Status: Downloaded"
          then
            systemctl restart web-db-admin
          fi
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        startAt = "hourly";
      };
      web-swag = {
        enable = true;
        description = "Web Service & Proxy";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" "web-db.service" ];
        path = [ pkgs.docker ];
        script = ''
          docker container stop web-swag >/dev/null 2>&1 || true ; \
          docker run --rm --name web-swag \
            -e URL=gustafson.me \
            -e SUBDOMAINS=www,homeassistant, \
            -e EXTRA_DOMAINS=gushome.org,www.gushome.org \
            -e VALIDATION=http \
            -e EMAIL=joshgstfsn@gmail.com \
            -e PUID=$(id -u www) \
            -e PGID=$(id -g www) \
            -e TZ=$(timedatectl show -p Timezone --value) \
            --tmpfs /config \
            -v /var/lib/swag_config/keys:/config/keys \
            -v /var/lib/swag_config/etc/letsencrypt:/config/etc/letsencrypt \
            -v /etc/nixos/www/site-confs/default.conf:/config/nginx/site-confs/default.conf \
            -v /etc/nixos/www/location-confs:/config/nginx/location-confs \
            -v /etc/nixos/www/proxy-confs/homeassistant.subdomain.conf:/config/nginx/proxy-confs/homeassistant.subdomain.conf \
            -v /var/lib/www:/config/www \
            -v /d/photos/Published:/config/www/published:ro \
            -v /var/lib/dav:/config/www/dav \
            --tmpfs /config/www/Photos/cache \
            --link web-db:db \
            -p 80:80 \
            -p 443:443 \
            lscr.io/linuxserver/swag
          '';
        serviceConfig = {
          Restart = "on-failure";
        };
      };
      web-swag-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull lscr.io/linuxserver/swag | grep "Status: Downloaded"
          then
            systemctl restart web-swag
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
