{ pkgs, ... }:
let
  pw = import ./.secrets/passwords.nix;
  machine = import ./machine.nix;
  zpoolProperties = "health capacity size free allocated";
in
{
  systemd.services = {
    status2mqtt-will = {
      path = with pkgs; [
        gawk
        mosquitto
      ] ++ (if machine.zfs then [ zfs ] else [ ]);
      script = ''
        advertize() {
          local NAME="$1"
          local PATH="$2"
          local UNIQUE_ID="server_${machine.hostName}_$(echo $PATH | ${pkgs.gnused}/bin/sed 's|/|_|g')"
          local PAYLOAD_JSON="{\"state_topic\":\"server/${machine.hostName}/$PATH\",\"name\":\"$NAME\",\"unique_id\":\"$UNIQUE_ID\",\"availability_topic\":\"server/${machine.hostName}/availability\",\"device\":{\"name\":\"Server ${machine.hostName}\",\"identifiers\":[\"server_${machine.hostName}\"]}}"

          ${pkgs.mosquitto}/bin/mosquitto_pub -V 5 -h mqtt.home.gustafson.me -u server -P ${pw.mqtt.server} -t homeassistant/sensor/server_${machine.hostName}/$UNIQUE_ID/config -r -m "$PAYLOAD_JSON"
        }

        advertize "Failed Services" systemd/failed

        advertize "Memory Used" memory/used
        advertize "Memory Free" memory/free

        df -x zfs -x tmpfs -x devtmpfs -x efivarfs -x nfs4 -x overlay | tail -n +2 | while read line
        do
          NAME="$(echo ''${line} | awk '{print $1}' | sed 's|^/dev/||' | sed 's|/|_|g')"
          advertize "Drive ''${NAME} Device" drive/''${NAME}/device
          advertize "Drive ''${NAME} Size" drive/''${NAME}/size
          advertize "Drive ''${NAME} Used" drive/''${NAME}/used
          advertize "Drive ''${NAME} Available" drive/''${NAME}/available
          advertize "Drive ''${NAME} Used %" drive/''${NAME}/capacity
          advertize "Drive ''${NAME} Mount" drive/''${NAME}/mount
        done
      ''
      + (if machine.zfs then ''
        for i in $(zpool list -H -o name)
        do
          for p in ${zpoolProperties}
          do
            advertize "ZPool $i $p" zpool/$i/$p
          done
        done
      '' else "")
      + ''

        systemctl start status2mqtt.service

        mosquitto_sub -V 5 -h mqtt.home.gustafson.me -u server -P ${pw.mqtt.server} -t server/${machine.hostName} --will-topic server/${machine.hostName}/availability --will-retain --will-payload offline
      '';
      serviceConfig = {
        Type = "simple";
        Restart = "always";
      };
      wantedBy = [ "multi-user.target" ];
      requires = [ "network-online.target" ];
    };
    status2mqtt = {
      path = with pkgs; [
        gawk
        mosquitto
        procps
      ] ++ (if machine.zfs then [ zfs ] else [ ]);
      script = ''
        pub() {
          local TOPIC="$1"
          local PAYLOAD="$2"
          mosquitto_pub -V 5 -h mqtt.home.gustafson.me -u server -P ${pw.mqtt.server} -t server/${machine.hostName}/''${TOPIC} -r -m "''${PAYLOAD}"
        }

        pub availability online

        pub systemd/failed "$(systemctl --failed -o json)"

        pub memory/used "$(free -L | awk '{ print $6 }')"
        pub memory/free "$(free -L | awk '{ print $8 }')"

        df -x zfs -x tmpfs -x devtmpfs -x efivarfs -x nfs4 -x overlay | tail -n +2 | while read line
        do
          NAME="$(echo ''${line} | awk '{print $1}' | sed 's|^/dev/||' | sed 's|/|_|g')"
          DEVICE="$(echo ''${line} | awk '{print $1}')"
          SIZE="$(echo ''${line} | awk '{print $2}')"
          USED="$(echo ''${line} | awk '{print $3}')"
          AVAILABLE="$(echo ''${line} | awk '{print $4}')"
          CAPACITY="$(echo ''${line} | awk '{print $5}' | sed 's|%||g')"
          MOUNT="$(echo ''${line} | awk '{print $6}')"
          pub drive/''${NAME}/device "''${DEVICE}"
          pub drive/''${NAME}/size "$((SIZE*1024))"
          pub drive/''${NAME}/used "$((USED*1024))"
          pub drive/''${NAME}/available "$((AVAILABLE*1024))"
          pub drive/''${NAME}/capacity "''${CAPACITY}"
          pub drive/''${NAME}/mount "''${MOUNT}"
        done
      ''
      + (if machine.zfs then ''
        for i in $(zpool list -H -o name)
        do
          for p in ${zpoolProperties}
          do
            pub zpool/$i/$p "$(zpool get $p -Hp -o value $i)"
          done
        done
      '' else "");
      serviceConfig = {
        Type = "oneshot";
      };
      requires = [ "status2mqtt-will.service" ];
      startAt = "minutely";
    };
  };
}
