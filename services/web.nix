# Manage DNS records for the below at: https://dash.cloudflare.com/4863ad256b1367a5598b6b30306133d8/home/domains
with builtins;
{ lib, pkgs, ... }:
let
  addresses = import ./../addresses.nix { inherit lib; };
  pw = import ./../.secrets/passwords.nix;
  encodeCaddyPassword = password: readFile (derivation {
    name = "encodeCaddyPassword";
    builder = "/bin/sh";
    args = [ "-c" "${pkgs.caddy}/bin/caddy hash-password -p '${password}' >$out" ];
    system = builtins.currentSystem;
  });
  publicDomain = "gustafson.me";
  caddyFile = ''
    ${publicDomain}, www.${publicDomain} {
      root * /usr/share/caddy
      encode gzip
      file_server
    }
    joyfulsong.org, www.joyfulsong.org {
      reverse_proxy joyfulsong.${addresses.network.domain}:80
    }
    journal.${publicDomain} {
      reverse_proxy journal.${addresses.network.domain}:80
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
    search-mcp.${publicDomain} {
      reverse_proxy searxng-mcp.${addresses.network.domain}:80
    }
    open-webui.${publicDomain} {
      reverse_proxy open-webui.${addresses.network.domain}:8080
    }
    jellyfin.${publicDomain} {
      reverse_proxy jellyfin.${addresses.network.domain}:8096
    }
    esphome.${publicDomain} {
      reverse_proxy esphome.${addresses.network.domain}:6052
      basic_auth {
        josh ${encodeCaddyPassword pw.esphome}
      }
    }
    zwave-main.${publicDomain} {
      reverse_proxy zwave-main.${addresses.network.domain}:8091
      basic_auth {
        josh ${encodeCaddyPassword pw.zwave}
      }
    }
    zwave-upstairs.${publicDomain} {
      reverse_proxy zwave-upstairs.${addresses.network.domain}:8091
      basic_auth {
        josh ${encodeCaddyPassword pw.zwave}
      }
    }
    zwave-basement.${publicDomain} {
      reverse_proxy zwave-basement.${addresses.network.domain}:8091
      basic_auth {
        josh ${encodeCaddyPassword pw.zwave}
      }
    }
    zwave-north.${publicDomain} {
      reverse_proxy zwave-north.${addresses.network.domain}:8091
      basic_auth {
        josh ${encodeCaddyPassword pw.zwave}
      }
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
