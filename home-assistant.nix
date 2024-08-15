{ config, pkgs, lib, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  pw = import ./.secrets/passwords.nix;
  service = "home-assistant";
  user = "home-assistant";
  group = "home-assistant";
  image = "ghcr.io/home-assistant/home-assistant:stable";
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
in
if (machine.hostName != addresses.records."${service}".host) then {} else
{
  imports = [ ./docker.nix ];

  environment.etc =
    let
      shades = [
        "basement_east_bedroom_shade"
        "basement_living_room_shade_1"
        "basement_living_room_shade_2"
        "basement_master_bedroom_shade_1"
        "basement_master_bedroom_shade_2"
        "basement_west_bedroom_shade"
        "boy_room_shade_1"
        "boy_room_shade_2"
        "boy_room_shade_3"
        "boy_room_shade_4"
        "boy_room_shade_5"
        "craft_room_shade_1"
        "craft_room_shade_2"
        "dining_room_shade_1"
        "dining_room_shade_2"
        "dining_room_upper_shade"
        "eden_hope_room_shade_1"
        "eden_hope_room_shade_2"
        "great_room_lower_left_shade"
        "great_room_lower_right_shade"
        "great_room_upper_left_shade"
        "great_room_upper_right_shade"
        "kayleigh_lyra_room_shade_1"
        "kayleigh_lyra_room_shade_2"
        "kayleigh_lyra_room_shade_3"
        "kitchen_shade_1"
        "kitchen_shade_2"
        "kitchen_shade_3"
        "loft_shade_1"
        "loft_shade_2"
        "loft_shade_3"
        "loft_shade_4"
        "master_bedroom_shade_1"
        "master_bedroom_shade_2"
        "master_bedroom_shade_3"
        "master_bedroom_shade_4"
        "master_bedroom_shade_5"
        "music_room_shade_1"
        "music_room_shade_2"
        "office_shade_1"
        "office_shade_2"
        "office_shade_3"
        "office_shade_4"
        "office_shade_5"
        "study_shade_1"
        "study_shade_2"
        "toy_room_shade_1"
        "toy_room_shade_2"
        "toy_room_shade_3"
        "workshop_north_shade"
      ];
      theater_devices = [
        {
          device = "bluray";
          index = "4";
        }
        {
          device = "shield";
          index = "B";
        }
      ];
      cec_map = [
        { command = "select";         code = "00"; }
        { command = "d_up";           code = "01"; }
        { command = "d_down";         code = "02"; }
        { command = "d_left";         code = "03"; }
        { command = "d_right";        code = "04"; }
        { command = "root_menu";      code = "09"; }
        { command = "setup_menu";     code = "0A"; }
        { command = "contents_menu";  code = "0B"; }
        { command = "favorite_menu";  code = "0C"; }
        { command = "exit";           code = "0D"; }
        { command = "enter";          code = "2B"; }
        { command = "clear";          code = "2C"; }
        { command = "channel_up";     code = "30"; }
        { command = "channel_down";   code = "31"; }
        { command = "prev_channel";   code = "32"; }
        { command = "display_info";   code = "35"; }
        { command = "power";          code = "40"; }
        { command = "volume_up";      code = "41"; }
        { command = "volume_down";    code = "42"; }
        { command = "mute";           code = "43"; }
        { command = "play";           code = "44"; }
        { command = "stop";           code = "45"; }
        { command = "pause";          code = "46"; }
        { command = "record";         code = "47"; }
        { command = "rewind";         code = "48"; }
        { command = "fast_forward";   code = "49"; }
        { command = "eject";          code = "4A"; }
        { command = "forward";        code = "4B"; }
        { command = "backward";       code = "4C"; }
        { command = "play_f";         code = "60"; }
        { command = "pause_play_f";   code = "61"; }
        { command = "power_toggle_f"; code = "6B"; }
        { command = "power_off_f";    code = "6C"; }
        { command = "power_on_f";     code = "6D"; }
        { command = "f1";             code = "71"; }
        { command = "f2";             code = "72"; }
        { command = "f3";             code = "73"; }
        { command = "f4";             code = "74"; }
        { command = "f5";             code = "75"; }
      ];
      gree_climate_devices = [
        {
          id = "server_climate";
          name = "Server Climate";
          host = "server-climate";
          mac = "94:24:b8:6c:0f:41";
        }
        {
          id = "theater_climate_unit";
          name = "Theater Climate Unit";
          host = "theater-climate";
          mac = "94:24:b8:6c:10:13";
        }
        {
          id = "workshop_climate_unit";
          name = "Workshop Climate Unit";
          host = "workshop-climate";
          mac = "94:24:b8:6d:47:92";
        }
      ];
    in
    builtins.listToAttrs(lib.lists.flatten(map(
      i: [
        {
          name = "${service}/input_number/${i}_auto_target.yaml";
          value = {
            text = ''
              min: 0
              max: 100
            '';
          };
        }
        {
          name = "${service}/input_boolean/${i}_window_open.yaml";
          value = { text = ""; };
        }
        {
          name = "${service}/input_boolean/${i}_user_override.yaml";
          value = { text = "initial: false"; };
        }
        {
          name = "${service}/automation/${i}_auto_set.yaml";
          value = {
            text = ''
              alias: ${i} auto set
              id: ${i}_auto_set
              mode: restart
              trigger:
                - platform: state
                  entity_id:
                    - input_number.${i}_auto_target
                - platform: state
                  entity_id:
                    - input_boolean.${i}_user_override
                  to: "off"
                - platform: state
                  entity_id:
                    - input_boolean.${i}_window_open
              condition:
                - condition: state
                  entity_id: input_boolean.${i}_user_override
                  state: "off"
              action:
                - variables:
                    p: "{{ [states('input_number.${i}_auto_target') | int, 50 if is_state('input_boolean.${i}_window_open', 'on') else 0] | max }}"
                - service: cover.set_cover_position
                  target:
                    entity_id: cover.${i}
                  data:
                    position: "{{ p }}"
            '';
          };
        }
        {
          name = "${service}/automation/${i}_user_set.yaml";
          value = {
            text = ''
              alias: ${i} user set
              id: ${i}_user_set
              mode: restart
              trigger:
                - platform: state
                  entity_id:
                    - cover.${i}
                  attribute: current_position
                  for:
                    seconds: 10
              condition: "{{ ([trigger.from_state.attributes.current_position | int, trigger.to_state.attributes.current_position | int, states('input_number.${i}_auto_target') | int] | sort)[1] != (trigger.to_state.attributes.current_position | int) }}"
              action:
                - service: input_boolean.turn_on
                  target:
                    entity_id: input_boolean.${i}_user_override
            '';
          };
        }
        {
          name = "${service}/automation/${i}_user_reset.yaml";
          value = {
            text = ''
              alias: ${i} user reset
              id: ${i}_user_reset
              mode: restart
              trigger:
                - platform: state
                  entity_id:
                    - input_boolean.${i}_user_override
                  to: "on"
                  for:
                    hours: 2
              action:
                - service: input_boolean.turn_off
                  target:
                    entity_id: input_boolean.${i}_user_override
            '';
          };
        }
      ]
    ) shades)) //
    builtins.listToAttrs(lib.lists.flatten(map(
      i: lib.lists.flatten(map(
        j: [
          {
            name = "${service}/shell_command/cec_${i.device}_${j.command}.yaml";
            value = {
              text = "(echo 'tx 1${i.index}:44:${j.code}'; sleep 0.050s; echo 'tx 1${i.index}:45') | nc -uw1 theater-cec 9526";
            };
          }
        ]
      ) cec_map)
    ) theater_devices)) //
    builtins.listToAttrs(lib.lists.flatten(map(
      i: [
        # { name = "${service}/input_boolean/${i.id}_lights.yaml"; value = { text = ""; }; }
        # { name = "${service}/input_boolean/${i.id}_xfan.yaml"; value = { text = ""; }; }
        # { name = "${service}/input_boolean/${i.id}_health.yaml"; value = { text = ""; }; }
        # { name = "${service}/input_boolean/${i.id}_sleep.yaml"; value = { text = ""; }; }
        # { name = "${service}/input_boolean/${i.id}_powersave.yaml"; value = { text = ""; }; }
        # { name = "${service}/input_boolean/${i.id}_eightdegheat.yaml"; value = { text = ""; }; }
        # { name = "${service}/input_boolean/${i.id}_air.yaml"; value = { text = ""; }; }
        {
          name = "${service}/climate/${i.id}.yaml";
          value = {
            text = ''
              platform: gree
              name: ${i.name}
              host: ${i.host}.home.gustafson.me
              port: 7000
              mac: ${i.mac}
              target_temp_step: 1
              # lights: input_boolean.${i.id}_lights
              # xfan: input_boolean.${i.id}_xfan
              # health: input_boolean.${i.id}_health
              # sleep: input_boolean.${i.id}_sleep
              # powersave: input_boolean.${i.id}_powersave
              # eightdegheat: input_boolean.${i.id}_eightdegheat
              # air: input_boolean.${i.id}_air
            '';
          };
        }
      ]
    ) gree_climate_devices)) //
    {
      "${service}/secrets.yaml".text = ''
        doorbell_password: ${pw.doorbell}
      '';
    };

  virtualisation.oci-containers.containers."${service}" = {
    image = image;
    autoStart = true;
    extraOptions = (addresses.dockerOptions service) ++ [
      "--privileged"
    ];
    environment = {
      PUID = toString config.users.users."${user}".uid;
      PGID = toString config.users.groups."${group}".gid;
      TZ = config.time.timeZone;
      VERSION = "latest";
    };
    volumes = [
      "/var/lib/${service}:/config"
      "/etc/${service}:/config/etc:ro"
      "/etc/${service}/secrets.yaml:/config/secrets.yaml:ro"
      "/etc/static:/etc/static:ro"
      "/nix/store:/nix/store:ro"
      "/run/dbus:/run/dbus:ro"
    ];
  };

  systemd = {
    services = docker-services {
      name = service;
      image = image;
      setup-script = ''
        if ! zfs list r/varlib/${service} >/dev/null 2>&1
        then
          zfs create r/varlib/${service}
          chown ${user}:${group} /var/lib/${service}
          rsync -arPx --delete /nas/backup/varlib/${service}/ /var/lib/${service}/ || true
        fi
      '';
      backup-script = ''
        mkdir -p /nas/backup/varlib/${service}
        rsync -arPx --delete /var/lib/${service}/ /nas/backup/varlib/${service}/
      '';
    };
  };
}
