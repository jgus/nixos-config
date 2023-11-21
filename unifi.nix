{ pkgs, ... }:

let
  database = "unifi";
  user = "unifi";
  password = "unifi";
in
{
  imports = [ ./docker.nix ];

  environment.etc = {
    "unifi-init-mongo.js".text = ''
db.getSiblingDB("${database}").createUser({user: "${user}", pwd: "${password}", roles: [{role: "dbOwner", db: "${database}"}]});
db.getSiblingDB("${database}_stat").createUser({user: "${user}", pwd: "${password}", roles: [{role: "dbOwner", db: "${database}_stat"}]});    '';
  };

  networking.firewall = {
    allowedTCPPorts = [ 8443 8080 8843 8880 6789 ];
    allowedUDPPorts = [ 3478 1900 5514 ];
  };

  systemd = {
    services = {
      unifi-db = {
        enable = true;
        description = "Unifi Network Database";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = [ pkgs.docker ];
        script = ''
          docker container stop unifi-db >/dev/null 2>&1 || true ; \
          docker run --rm --name unifi-db \
            -v /var/lib/unifi-db:/data/db \
            -v /etc/unifi-init-mongo.js:/docker-entrypoint-initdb.d/init-mongo.js:ro \
            docker.io/mongo:4.4.18
          '';
        serviceConfig = {
          Restart = "on-failure";
        };
      };
      unifi-db-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull docker.io/mongo:4.4.18 | grep "Status: Downloaded"
          then
            systemctl stop unifi-network
            systemctl restart unifi-db
            systemctl restart unifi-network
          fi
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        startAt = "hourly";
      };
      unifi-network = {
        enable = true;
        description = "Unifi Network";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" "unifi-db.service" ];
        path = [ pkgs.docker ];
        script = ''
          docker container stop unifi-network >/dev/null 2>&1 || true ; \
          docker run --rm --name unifi-network \
            -p 8443:8443 \
            -p 3478:3478/udp \
            -p 10001:10001/udp \
            -p 8080:8080 \
            -p 1900:1900/udp \
            -p 8843:8843 \
            -p 8880:8880 \
            -p 6789:6789 \
            -p 5514:5514/udp \
            -e PUID=$(id -u josh) \
            -e PGID=$(id -g josh) \
            -e TZ=$(timedatectl show -p Timezone --value) \
            -e MONGO_USER=${user} \
            -e MONGO_PASS=${password} \
            -e MONGO_HOST=unifi-db \
            -e MONGO_PORT=27017 \
            -e MONGO_DBNAME=${database} \
            -v /var/lib/unifi-network:/config \
            --link unifi-db \
            lscr.io/linuxserver/unifi-network-application
          '';
        serviceConfig = {
          Restart = "on-failure";
        };
      };
      unifi-network-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull lscr.io/linuxserver/unifi-network-application | grep "Status: Downloaded"
          then
            systemctl restart unifi-network
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
