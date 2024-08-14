{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  db_image = "mysql:5.7";
  db_admin_image = "phpmyadmin/phpmyadmin";
  swag_image = "lscr.io/linuxserver/swag";
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
in
if (machine.hostName != addresses.records.web-swag.host) then {} else
{
  imports = [ ./docker.nix ];

  virtualisation.oci-containers.containers.web-db = {
    image = db_image;
    autoStart = true;
    extraOptions = [
      "--network=macvlan"
      "--mac-address=${addresses.records.web-db.mac}"
      "--ip=${addresses.records.web-db.ip}"
    ];
    volumes = [
      "/var/lib/web_db_data:/var/lib/mysql"
    ];
  };

  virtualisation.oci-containers.containers.web-db-admin = {
    image = db_admin_image;
    autoStart = true;
    dependsOn = [ "web-db" ];
    extraOptions = [
      "--network=macvlan"
      "--mac-address=${addresses.records.web-db-admin.mac}"
      "--ip=${addresses.records.web-db-admin.ip}"
    ];
    ports = [
      "8101:80"
    ];
    volumes = [
      "/var/lib/web_db_admin_sessions:/sessions"
    ];
  };

  virtualisation.oci-containers.containers.web-swag = {
    image = swag_image;
    autoStart = true;
    dependsOn = [ "web-db" ];
    extraOptions = [
      "--tmpfs=/config"
      "--tmpfs=/config/www/Photos/cache"
      "--link=web-db:db"
      "--network=macvlan"
      "--mac-address=${addresses.records.web-swag.mac}"
      "--ip=${addresses.records.web-swag.ip}"
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
      "/nas/photos/Published:/config/www/published:ro"
      "/var/lib/dav:/config/www/dav"
    ];
  };

  systemd = {
    services = docker-services {
      name = "web-db";
      image = db_image;
      setup-script = ''
        if ! zfs list r/varlib/web_db_data >/dev/null 2>&1
        then
          zfs create r/varlib/web_db_data
          rsync -arPx --delete /nas/backup/varlib/web_db_data/ /var/lib/web_db_data/ || true
        fi
      '';
      backup-script = ''
        mkdir -p /nas/backup/varlib/web_db_data
        rsync -arPx --delete /var/lib/web_db_data/ /nas/backup/varlib/web_db_data/
      '';
    } // docker-services {
      name = "web-db-admin";
      image = db_admin_image;
      setup-script = ''
        if ! zfs list r/varlib/web_db_admin_sessions >/dev/null 2>&1
        then
          zfs create r/varlib/web_db_admin_sessions
          rsync -arPx --delete /nas/backup/varlib/web_db_admin_sessions/ /var/lib/web_db_admin_sessions/ || true
        fi
      '';
      backup-script = ''
        mkdir -p /nas/backup/varlib/web_db_admin_sessions
        rsync -arPx --delete /var/lib/web_db_admin_sessions/ /nas/backup/varlib/web_db_admin_sessions/
      '';
    } // docker-services {
      name = "web-swag";
      image = swag_image;
      setup-script = ''
        if ! zfs list r/varlib/web_proxy_config >/dev/null 2>&1
        then
          zfs create r/varlib/web_proxy_config
          rsync -arPx --delete /nas/backup/varlib/web_proxy_config/ /var/lib/web_proxy_config/ || true
        fi
        if ! zfs list r/varlib/swag_config >/dev/null 2>&1
        then
          zfs create r/varlib/swag_config
          rsync -arPx --delete /nas/backup/varlib/swag_config/ /var/lib/swag_config/ || true
          mkdir -p /var/lib/swag_config/keys
          mkdir -p /var/lib/swag_config/etc/letsencrypt
        fi
        if ! zfs list r/varlib/www >/dev/null 2>&1
        then
          zfs create r/varlib/www
          rsync -arPx --delete /nas/backup/varlib/www/ /var/lib/www/ || true
        fi
        if ! zfs list r/varlib/dav >/dev/null 2>&1
        then
          zfs create r/varlib/dav
          mkdir -p /var/lib/dav/tmp
          mkdir -p /var/lib/dav/files
          chown www:www /var/lib/dav
          chown www:www /var/lib/dav/tmp
          chown www:www /var/lib/dav/files
          rsync -arPx --delete /nas/backup/varlib/dav/ /var/lib/dav/ || true
        fi
      '';
      backup-script = ''
        mkdir -p /nas/backup/varlib/web_proxy_config
        rsync -arPx --delete /var/lib/web_proxy_config/ /nas/backup/varlib/web_proxy_config/
        mkdir -p /nas/backup/varlib/swag_config
        rsync -arPx --delete /var/lib/swag_config/ /nas/backup/varlib/swag_config/
        mkdir -p /nas/backup/varlib/www
        rsync -arPx --delete /var/lib/www/ /nas/backup/varlib/www/
        mkdir -p /nas/backup/varlib/dav
        rsync -arPx --delete /var/lib/dav/ /nas/backup/varlib/dav/
      '';
    };
  };
}
