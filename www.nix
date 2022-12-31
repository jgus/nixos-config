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
    web-proxy-setup.text = ''
      ${pkgs.zfs}/bin/zfs list s/varlib/web_db_data >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create s/varlib/web_db_data
      ${pkgs.zfs}/bin/zfs list s/varlib/web_db_admin_sessions >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create s/varlib/web_db_admin_sessions
      ${pkgs.zfs}/bin/zfs list s/varlib/web_proxy_config >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create s/varlib/web_proxy_config
      ${pkgs.zfs}/bin/zfs list s/varlib/www >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create s/varlib/www
      ${pkgs.zfs}/bin/zfs list s/varlib/dav >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create s/varlib/dav
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
      web-proxy = {
        enable = true;
        description = "Web Service & Proxy";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" "web-db.service" ];
        path = [ pkgs.docker ];
        script = ''
          docker run --rm --name web-proxy \
            -e URL=gustafson.me \
            -e EXTRA_DOMAINS=gushome.org \
            -e SUBDOMAINS=www, \
            -e VALIDATION=http \
            -e EMAIL=j@gustafson.me \
            -e PUID=$(id -u www) \
            -e PGID=$(id -g www) \
            -e TZ=$(timedatectl show -p Timezone --value) \
            -v /var/lib/web_proxy_config:/config \
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
      web-proxy-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull lscr.io/linuxserver/swag | grep "Status: Downloaded"
          then
            systemctl restart web-proxy
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
