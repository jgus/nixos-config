# Manage DNS records for the below at: https://dash.cloudflare.com/4863ad256b1367a5598b6b30306133d8/home/domains
{ addresses, pkgs, ... }:
let
  publicDomain = "gustafson.me";
  securityHeaders = { frameOptions ? "DENY", ... }: ''
    header {
      Strict-Transport-Security "max-age=31536000; includeSubDomains"
      X-Frame-Options "${frameOptions}"
      X-Content-Type-Options "nosniff"
      Permissions-Policy "interest-cohort=()"
      Referrer-Policy "strict-origin-when-cross-origin"
    }
  '';
  caddyFile = ''
    ${publicDomain}, www.${publicDomain} {
      root * /usr/share/caddy
      encode gzip
      file_server
      ${securityHeaders {}}
    }
    joyfulsong.org, www.joyfulsong.org {
      reverse_proxy joyfulsong.${addresses.network.domain}:80
      ${securityHeaders {}}
    }
    journal.${publicDomain} {
      reverse_proxy journal.${addresses.network.domain}:80
      ${securityHeaders {}}
    }
    ha.${publicDomain} {
      reverse_proxy ha.${addresses.network.domain}:8123
      ${securityHeaders {}}
    }
    komga.${publicDomain} {
      reverse_proxy komga.${addresses.network.domain}:25600
      ${securityHeaders {}}
    }
    office.${publicDomain} {
      reverse_proxy onlyoffice.${addresses.network.domain}:80
      ${securityHeaders { frameOptions = "SAMEORIGIN"; }}
    }
    drive.${publicDomain} {
      reverse_proxy owncloud.${addresses.network.domain}:8080
      ${securityHeaders { frameOptions = "SAMEORIGIN"; }}
    }
    audiobookshelf.${publicDomain} {
      reverse_proxy audiobookshelf.${addresses.network.domain}:80
      ${securityHeaders {}}
    }
    calibre.${publicDomain} {
      reverse_proxy calibre.${addresses.network.domain}:8083
      ${securityHeaders {}}
    }
    search.${publicDomain} {
      reverse_proxy searxng.${addresses.network.domain}:8080
      ${securityHeaders {}}
    }
    search-mcp.${publicDomain} {
      reverse_proxy searxng-mcp.${addresses.network.domain}:80
      ${securityHeaders {}}
    }
    open-webui.${publicDomain} {
      reverse_proxy open-webui.${addresses.network.domain}:8080
      ${securityHeaders {}}
    }
    jellyfin.${publicDomain} {
      reverse_proxy jellyfin.${addresses.network.domain}:8096
      ${securityHeaders {}}
    }
    esphome.${publicDomain} {
      @internal client_ip private_ranges ${addresses.network.prefix6}/64
      handle @internal {
        reverse_proxy esphome.${addresses.network.domain}:6052
        ${securityHeaders {}}
      }
      handle {
        respond "Access denied" 403
      }
    }
    zwave-main.${publicDomain} {
      @internal client_ip private_ranges ${addresses.network.prefix6}/64
      handle @internal {
        reverse_proxy zwave-main.${addresses.network.domain}:8091
        ${securityHeaders {}}
      }
      handle {
        respond "Access denied" 403
      }
    }
    zwave-upstairs.${publicDomain} {
      @internal client_ip private_ranges ${addresses.network.prefix6}/64
      handle @internal {
        reverse_proxy zwave-upstairs.${addresses.network.domain}:8091
        ${securityHeaders {}}
      }
      handle {
        respond "Access denied" 403
      }
    }
    zwave-basement.${publicDomain} {
      @internal client_ip private_ranges ${addresses.network.prefix6}/64
      handle @internal {
        reverse_proxy zwave-basement.${addresses.network.domain}:8091
        ${securityHeaders {}}
      }
      handle {
        respond "Access denied" 403
      }
    }
    zwave-north.${publicDomain} {
      @internal client_ip private_ranges ${addresses.network.prefix6}/64
      handle @internal {
        reverse_proxy zwave-north.${addresses.network.domain}:8091
        ${securityHeaders {}}
      }
      handle {
        respond "Access denied" 403
      }
    }
  '';
in
{
  name = "web";
  extraStorage = [ "web_data" ];
  container = {
    pullImage = import ../images/caddy.nix;
    ports = [
      "80"
      "443"
    ];
    configVolume = "/config";
    volumes = storagePath: [
      "${storagePath "web_data"}:/data"
      "${pkgs.writeText "Caddyfile" caddyFile}:/etc/caddy/Caddyfile:ro"
      "/storage/service/www:/usr/share/caddy"
    ];
  };
}
