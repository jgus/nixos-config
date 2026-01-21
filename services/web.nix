# Manage DNS records for the below at: https://dash.cloudflare.com/4863ad256b1367a5598b6b30306133d8/home/domains
{ addresses, pkgs, ... }:
let
  domain = addresses.network.domain;
  publicDomain = addresses.network.publicDomain;
  securityHeaders = { frameOptionsDeny ? true, ... }: ''
    header {
      Strict-Transport-Security "max-age=31536000; includeSubDomains"
      ${if frameOptionsDeny then "X-Frame-Options \"DENY\"" else ""}
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
      reverse_proxy joyfulsong.${domain}:80
      ${securityHeaders {}}
    }
    journal.${publicDomain} {
      reverse_proxy journal.${domain}:80
      ${securityHeaders {}}
    }
    ha.${publicDomain} {
      reverse_proxy ha.${domain}:8123
      ${securityHeaders {}}
    }
    komga.${publicDomain} {
      reverse_proxy komga.${domain}:25600
      ${securityHeaders {}}
    }
    office.${publicDomain} {
      reverse_proxy onlyoffice.${domain}:80
      ${securityHeaders { frameOptionsDeny = false; }}
    }
    drive.${publicDomain} {
      reverse_proxy owncloud.${domain}:8080
      ${securityHeaders { frameOptionsDeny = false; }}
    }
    audiobookshelf.${publicDomain} {
      reverse_proxy audiobookshelf.${domain}:80
      ${securityHeaders {}}
    }
    calibre.${publicDomain} {
      reverse_proxy calibre.${domain}:8083
      ${securityHeaders {}}
    }
    search.${publicDomain} {
      reverse_proxy searxng.${domain}:8080
      ${securityHeaders {}}
    }
    search-mcp.${publicDomain} {
      reverse_proxy searxng-mcp.${domain}:80
      ${securityHeaders {}}
    }
    open-webui.${publicDomain} {
      reverse_proxy open-webui.${domain}:8080
      ${securityHeaders {}}
    }
    jellyfin.${publicDomain} {
      reverse_proxy jellyfin.${domain}:8096
      ${securityHeaders {}}
    }
    esphome.${publicDomain} {
      @internal client_ip private_ranges ${addresses.network.local6}
      handle @internal {
        reverse_proxy esphome.${domain}:6052
        ${securityHeaders {}}
      }
      handle {
        respond "Access denied" 403
      }
    }
    zwave-main.${publicDomain} {
      @internal client_ip private_ranges ${addresses.network.local6}
      handle @internal {
        reverse_proxy zwave-main.${domain}:8091
        ${securityHeaders {}}
      }
      handle {
        respond "Access denied" 403
      }
    }
    zwave-upstairs.${publicDomain} {
      @internal client_ip private_ranges ${addresses.network.local6}
      handle @internal {
        reverse_proxy zwave-upstairs.${domain}:8091
        ${securityHeaders {}}
      }
      handle {
        respond "Access denied" 403
      }
    }
    zwave-basement.${publicDomain} {
      @internal client_ip private_ranges ${addresses.network.local6}
      handle @internal {
        reverse_proxy zwave-basement.${domain}:8091
        ${securityHeaders {}}
      }
      handle {
        respond "Access denied" 403
      }
    }
    zwave-north.${publicDomain} {
      @internal client_ip private_ranges ${addresses.network.local6}
      handle @internal {
        reverse_proxy zwave-north.${domain}:8091
        ${securityHeaders {}}
      }
      handle {
        respond "Access denied" 403
      }
    }
    code.${publicDomain} {
      @internal client_ip private_ranges ${addresses.network.local6}
      handle @internal {
        reverse_proxy code-server.${domain}:8443
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
