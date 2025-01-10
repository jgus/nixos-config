{ pkgs, ... }:
let
  pw = import ./.secrets/passwords.nix;
  machine = import ./machine.nix;
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
          local UNIQUE_ID="server_${machine.hostName}_$(echo $TOPIC_PATH | ${pkgs.gnused}/bin/sed 's|/|_|g')"
          local DEVICE_JSON="{\"name\":\"Server ${machine.hostName}\",\"identifiers\":[\"server_${machine.hostName}\"]}"
          local PAYLOAD_JSON="{\"state_topic\":\"server/${machine.hostName}/$TOPIC_PATH\""
          PAYLOAD_JSON="$PAYLOAD_JSON,\"name\":\"$NAME\""
          PAYLOAD_JSON="$PAYLOAD_JSON,\"unique_id\":\"$UNIQUE_ID\""
          PAYLOAD_JSON="$PAYLOAD_JSON,\"availability_topic\":\"server/${machine.hostName}/availability\""
          PAYLOAD_JSON="$PAYLOAD_JSON,\"device\":$DEVICE_JSON"
          if [[ "x$UNIT" != "x" ]]
          then
            PAYLOAD_JSON="$PAYLOAD_JSON,\"unit_of_measurement\":\"$UNIT\""
          fi
          PAYLOAD_JSON="$PAYLOAD_JSON}"

          ${pkgs.mosquitto}/bin/mosquitto_pub -V 5 -h mqtt.home.gustafson.me -u server -P ${pw.mqtt.server} -t homeassistant/sensor/server_${machine.hostName}/$UNIQUE_ID/config -r -m "$PAYLOAD_JSON"
        }

        NAME="Failed Services" TOPIC_PATH=systemd/failed advertize

        NAME="Memory Used" TOPIC_PATH=memory/used UNIT="bytes" advertize
        NAME="Memory Free" TOPIC_PATH=memory/free UNIT="bytes" advertize

        df -x zfs -x tmpfs -x devtmpfs -x efivarfs -x nfs4 -x overlay -x fuse | tail -n +2 | while read line
        do
          DNAME="$(echo ''${line} | awk '{print $1}' | sed 's|^/dev/||' | sed 's|/|_|g')"
          NAME="Drive ''${DNAME} Device" TOPIC_PATH=drive/''${DNAME}/device advertize
          NAME="Drive ''${DNAME} Size" TOPIC_PATH=drive/''${DNAME}/size UNIT="bytes" advertize
          NAME="Drive ''${DNAME} Used" TOPIC_PATH=drive/''${DNAME}/used UNIT="bytes" advertize
          NAME="Drive ''${DNAME} Available" TOPIC_PATH=drive/''${DNAME}/available UNIT="bytes" advertize
          NAME="Drive ''${DNAME} Used %" TOPIC_PATH=drive/''${DNAME}/capacity UNIT="%" advertize
          NAME="Drive ''${DNAME} Mount" TOPIC_PATH=drive/''${DNAME}/mount advertize
        done
      ''
      + (if machine.zfs then ''
        for i in $(zpool list -H -o name)
        do
          for p in health
          do
            NAME="ZPool $i $p" TOPIC_PATH=zpool/$i/$p advertize
          done
          for p in capacity
          do
            NAME="ZPool $i $p" TOPIC_PATH=zpool/$i/$p UNIT="%" advertize
          done
          for p in size free allocated
          do
            NAME="ZPool $i $p" TOPIC_PATH=zpool/$i/$p UNIT="bytes" advertize
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
          for p in health capacity size free allocated
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
