{ addresses, config, lib, machine, pkgs, ... }:
{
  systemd.services = {
    status2mqtt-will = {
      path = with pkgs; [
        gawk
        mosquitto
      ] ++ lib.optional machine.zfs zfs;
      script = ''
        add_sensor() {
          local TOPIC="$1"
          local NAME="$2"
          local UNIQUE_ID="$3"
          local UNIT="$4"

          local SENSOR_JSON="\"$UNIQUE_ID\":{"
          SENSOR_JSON="$SENSOR_JSON\"p\":\"sensor\","
          SENSOR_JSON="$SENSOR_JSON\"name\":\"$NAME\","
          SENSOR_JSON="$SENSOR_JSON\"state_topic\":\"server/${config.networking.hostName}/$TOPIC\","
          SENSOR_JSON="$SENSOR_JSON\"unique_id\":\"server_${config.networking.hostName}_$UNIQUE_ID\","
          SENSOR_JSON="$SENSOR_JSON\"availability_topic\":\"server/${config.networking.hostName}/availability\""
          if [[ "x$UNIT" != "x" ]]; then
            SENSOR_JSON="$SENSOR_JSON,\"unit_of_measurement\":\"$UNIT\""
          fi
          SENSOR_JSON="$SENSOR_JSON}"

          if [[ -z "$SENSORS_JSON" ]]; then
            SENSORS_JSON="$SENSOR_JSON"
          else
            SENSORS_JSON="$SENSORS_JSON,$SENSOR_JSON"
          fi
        }

        SENSORS_JSON=""

        add_sensor "systemd/failed" "Failed Services" "systemd_failed" ""

        add_sensor "memory/used" "Memory Used" "memory_used" "bytes"
        add_sensor "memory/free" "Memory Free" "memory_free" "bytes"

        while IFS= read -r line; do
          DNAME="$(echo ''${line} | awk '{print $1}' | sed 's|^/dev/||' | sed 's|/|_|g')"
          add_sensor "drive/''${DNAME}/device" "Drive ''${DNAME} Device" "drive_''${DNAME}_device" ""
          add_sensor "drive/''${DNAME}/size" "Drive ''${DNAME} Size" "drive_''${DNAME}_size" "bytes"
          add_sensor "drive/''${DNAME}/used" "Drive ''${DNAME} Used" "drive_''${DNAME}_used" "bytes"
          add_sensor "drive/''${DNAME}/available" "Drive ''${DNAME} Available" "drive_''${DNAME}_available" "bytes"
          add_sensor "drive/''${DNAME}/capacity" "Drive ''${DNAME} Capacity" "drive_''${DNAME}_capacity" "%"
          add_sensor "drive/''${DNAME}/mount" "Drive ''${DNAME} Mount" "drive_''${DNAME}_mount" ""
        done < <(df -x zfs -x tmpfs -x devtmpfs -x efivarfs -x nfs4 -x overlay -x fuse | tail -n +2)
      '' + lib.optionalString machine.zfs ''
        for i in $(zpool list -H -o name)
        do
          add_sensor "zpool/$i/health" "ZPool $i Health" "zpool_''${i}_health" ""
          add_sensor "zpool/$i/capacity" "ZPool $i Capacity" "zpool_''${i}_capacity" "%"
          add_sensor "zpool/$i/size" "ZPool $i Size" "zpool_''${i}_size" "bytes"
          add_sensor "zpool/$i/free" "ZPool $i Free" "zpool_''${i}_free" "bytes"
          add_sensor "zpool/$i/allocated" "ZPool $i Allocated" "zpool_''${i}_allocated" "bytes"
        done
      '' + ''

        PAYLOAD_JSON="{\"dev\":{\"ids\":\"server_${config.networking.hostName}\",\"name\":\"Server ${config.networking.hostName}\"},\"o\":{\"name\":\"status2mqtt\",\"sw\":\"1.0\"},\"cmps\":{$SENSORS_JSON}}"
        ${pkgs.mosquitto}/bin/mosquitto_pub -V 5 -h mqtt.${addresses.network.domain} -u server -P $(cat ${config.sops.secrets."mqtt/server".path}) -t homeassistant/device/server_${config.networking.hostName}/config -r -m "$PAYLOAD_JSON"

        systemctl start status2mqtt.service

        mosquitto_sub -V 5 -h mqtt.${addresses.network.domain} -u server -P $(cat ${config.sops.secrets."mqtt/server".path}) -t server/${config.networking.hostName} --will-topic server/${config.networking.hostName}/availability --will-retain --will-payload offline
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
      ] ++ lib.optional machine.zfs zfs;
      script = ''
        pub() {
          local TOPIC="$1"
          local PAYLOAD="$2"
          mosquitto_pub -V 5 -h mqtt.${addresses.network.domain} -u server -P $(cat ${config.sops.secrets."mqtt/server".path}) -t server/${config.networking.hostName}/''${TOPIC} -r -m "''${PAYLOAD}"
        }

        pub availability online

        pub systemd/failed "$(systemctl --failed -o json)"

        pub memory/used "$(free -L | awk '{ print $6 }')"
        pub memory/free "$(free -L | awk '{ print $8 }')"

        df -x zfs -x tmpfs -x devtmpfs -x efivarfs -x nfs4 -x overlay -x fuse | tail -n +2 | while read line
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
      '' + lib.optionalString machine.zfs ''
        for i in $(zpool list -H -o name)
        do
          for p in health capacity size free allocated
          do
            pub zpool/$i/$p "$(zpool get $p -Hp -o value $i)"
          done
        done
      '';
      serviceConfig = {
        Type = "oneshot";
      };
      requires = [ "status2mqtt-will.service" ];
      startAt = "minutely";
    };
  };
  sops.secrets."mqtt/server" = { };
}
