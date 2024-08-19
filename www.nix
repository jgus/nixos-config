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

  fileSystems = builtins.listToAttrs (map (name:
    {
      name = name;
      value = {
        device = "localhost:/varlib-${name}";
        fsType = "glusterfs";
      };
    }
  ) [ "www" "dav" "swag_config" "web_db_data" "web_db_admin_sessions" ]);

  virtualisation.oci-containers.containers.web-db = {
    image = db_image;
    autoStart = true;
    extraOptions = (addresses.dockerOptions "web-db");
    volumes = [
      "/var/lib/web_db_data:/var/lib/mysql"
    ];
  };

  virtualisation.oci-containers.containers.web-db-admin = {
    image = db_admin_image;
    autoStart = true;
    dependsOn = [ "web-db" ];
    extraOptions = (addresses.dockerOptions "web-db-admin");
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
    extraOptions = (addresses.dockerOptions "web-swag") ++ [
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
      requires = [ "var-lib-web_db_data.mount" ];
    } // docker-services {
      name = "web-db-admin";
      image = db_admin_image;
      requires = [ "var-lib-web_db_admin_sessions.mount" ];
    } // docker-services {
      name = "web-swag";
      image = swag_image;
      requires = [ "var-lib-swag_config.mount" "var-lib-www.mount" "var-lib-dav.mount" "nas.mount" ];
    };
  };
}
