{ pkgs, ... }:
let
  addresses = import ./../addresses.nix;
  publicDomain = "gustafson.me";
  caddyFile = ''
    ${publicDomain}, www.${publicDomain} {
      handle_path /journal/* {
        reverse_proxy journal.${addresses.network.domain}:80
      }
      handle {
        root * /usr/share/caddy
        encode gzip
        file_server
      }
    }
    ha.${publicDomain} {
      reverse_proxy ha.${addresses.network.domain}:8123
    }
    komga.${publicDomain} {
      reverse_proxy komga.${addresses.network.domain}:25600
    }
    office.${publicDomain} {
      reverse_proxy onlyoffice.${addresses.network.domain}:80
    }
    drive.${publicDomain} {
      reverse_proxy owncloud.${addresses.network.domain}:8080
    }
    audiobookshelf.${publicDomain} {
      reverse_proxy audiobookshelf.${addresses.network.domain}:80
    }
    calibre.${publicDomain} {
      reverse_proxy calibre.${addresses.network.domain}:8083
    }
    search.${publicDomain} {
      reverse_proxy searxng.${addresses.network.domain}:8080
    }
    open-webui.${publicDomain} {
      reverse_proxy open-webui.${addresses.network.domain}:8080
    }
    jellyfin.${publicDomain} {
      reverse_proxy jellyfin.${addresses.network.domain}:8096
    }
  '';
in
{
  name = "web";
  extraStorage = [ "web_data" ];
  docker = {
    image = "caddy";
    ports = [
      "80"
      "443"
    ];
    configVolume = "/config";
    volumes = storagePath: [
      "${storagePath "web_data"}:/data"
      "${pkgs.writeText "Caddyfile" caddyFile}:/etc/caddy/Caddyfile"
      "/storage/service/www:/usr/share/caddy"
    ];
  };
}

