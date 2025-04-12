with builtins;
let
  pw = import ./../.secrets/passwords.nix;
  name = "home-assistant";
  user = "home-assistant";
  group = "home-assistant";
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
    { command = "select"; code = "00"; }
    { command = "d_up"; code = "01"; }
    { command = "d_down"; code = "02"; }
    { command = "d_left"; code = "03"; }
    { command = "d_right"; code = "04"; }
    { command = "root_menu"; code = "09"; }
    { command = "setup_menu"; code = "0A"; }
    { command = "contents_menu"; code = "0B"; }
    { command = "favorite_menu"; code = "0C"; }
    { command = "exit"; code = "0D"; }
    { command = "enter"; code = "2B"; }
    { command = "clear"; code = "2C"; }
    { command = "channel_up"; code = "30"; }
    { command = "channel_down"; code = "31"; }
    { command = "prev_channel"; code = "32"; }
    { command = "display_info"; code = "35"; }
    { command = "power"; code = "40"; }
    { command = "volume_up"; code = "41"; }
    { command = "volume_down"; code = "42"; }
    { command = "mute"; code = "43"; }
    { command = "play"; code = "44"; }
    { command = "stop"; code = "45"; }
    { command = "pause"; code = "46"; }
    { command = "record"; code = "47"; }
    { command = "rewind"; code = "48"; }
    { command = "fast_forward"; code = "49"; }
    { command = "eject"; code = "4A"; }
    { command = "forward"; code = "4B"; }
    { command = "backward"; code = "4C"; }
    { command = "play_f"; code = "60"; }
    { command = "pause_play_f"; code = "61"; }
    { command = "power_toggle_f"; code = "6B"; }
    { command = "power_off_f"; code = "6C"; }
    { command = "power_on_f"; code = "6D"; }
    { command = "f1"; code = "71"; }
    { command = "f2"; code = "72"; }
    { command = "f3"; code = "73"; }
    { command = "f4"; code = "74"; }
    { command = "f5"; code = "75"; }
  ];
  gree_climate_devices = [
    {
      id = "server_climate";
      name = "Server Climate";
      host = "server-climate";
      mac = "9424b86c0f41";
    }
    {
      id = "theater_climate_unit";
      name = "Theater Climate Unit";
      host = "theater-climate";
      mac = "9424b86c1013";
    }
    {
      id = "workshop_climate_unit";
      name = "Workshop Climate Unit";
      host = "workshop-climate";
      mac = "9424b86d4792";
    }
  ];
  light_groups = {
    "Great Room" = [
      "light.dining_room_light"
      "light.dining_room_switch_virtual"
      "light.great_room_light"
      "light.great_room_switch_virtual_e"
      "light.great_room_switch_virtual_s"
      "light.great_room_switch_virtual_w"
      "light.loft_light"
      "light.main_hall_light"
      "light.main_hall_switch_virtual_c"
      "light.main_hall_switch_virtual_n"
      "light.stair_lights"
      "light.stairs_switch_virtual"
      "light.upstairs_hall_east_light"
      "light.upstairs_hall_north_light"
      "light.upstairs_hall_north_switch_virtual_n"
      "light.upstairs_hall_north_switch_virtual_s"
    ];
    "Kitchen" = [
      "light.kitchen_leds"
      "light.kitchen_light"
      "light.kitchen_pendant_light"
      "light.kitchen_switch_virtual_nw"
      "light.kitchen_switch_virtual_se"
      "light.kitchen_switch_virtual_sw"
      "light.range_hood_light"
    ];
  };
  device_ids = {
    "light.dining_room_light" = "e1590e93793f8a474586e38dfb4ac92b";
    "light.dining_room_switch_virtual" = "612e6c3ea0dd262fd0f5d576222bc51d";
    "light.great_room_light" = "f4590329c3ef0b500910721f23162451";
    "light.great_room_switch_virtual_e" = "d62ae3c5c11c2971b89b0d257776e7ad";
    "light.great_room_switch_virtual_s" = "a7cdf2bd153b628a7c8965ea8a944e28";
    "light.great_room_switch_virtual_w" = "d1cba419cc50f544714a950bee822436";
    "light.kitchen_leds" = "302d19cfd2fe0b2a2f3a6c076f5d3f29";
    "light.kitchen_light" = "584bac53fe98027ddd194be977c1060e";
    "light.kitchen_pendant_light" = "fc605fa06114f6cf73247982688cbd93";
    "light.kitchen_switch_virtual_nw" = "78f9c391edc3967489ba6bd945a54007";
    "light.kitchen_switch_virtual_se" = "bc3ae78c7f4869b3a14d784df468fde7";
    "light.kitchen_switch_virtual_sw" = "1fafbcb70f54e15aabb6e35c1e857f71";
    "light.loft_light" = "c3ca6b4a3f527f4a03d850844948db66";
    "light.main_hall_light" = "5accedf8ff58eeeb44c8e7afcfb497b1";
    "light.main_hall_switch_virtual_c" = "051537710dbd32b63bde7d8f993c692e";
    "light.main_hall_switch_virtual_n" = "29f3d260c0c67fce1236717096a6257d";
    "light.range_hood_light" = null;
    "light.stair_lights" = null;
    "light.stairs_switch_virtual" = "a2af70357e94775f40f9332628ff0123";
    "light.upstairs_hall_east_light" = "def24a95c302daa49ca40cd50139cd1f";
    "light.upstairs_hall_north_light" = "256bc73b6c63fac342e6936f7187fb58";
    "light.upstairs_hall_north_switch_virtual_n" = "b0dd43b9273d7b0ccde86cfd1dead619";
    "light.upstairs_hall_north_switch_virtual_s" = "1c74e3a6baf321724a557775e3c20cbc";
  };
in
{ config, pkgs, lib, ... }:
let
  windows =
    map
      (line:
        let
          parts = lib.strings.splitString "," line;
          location = elemAt parts 0;
          index = elemAt parts 1;
          suffix = if (index == "") then "" else "_${index}";
          has_shade = (elemAt parts 2) == "Y";
          type = elemAt parts 3;
          on_ground = (elemAt parts 4) == "Y";
          opens = type != "F";
          open_limit = if (type == "V") then 50 else 100;
          window_name = "${location}_window${suffix}";
          shade_name = "${location}_shade${suffix}";
          # window_open_name = "${window_name}_open";
          window_open_name = "${shade_name}_window_open";
          target_name = "${shade_name}_auto_target";
          override_name = "${shade_name}_user_override";
        in
        {
          inherit location index has_shade type on_ground opens open_limit window_name shade_name window_open_name target_name override_name;
        }
      )
      (lib.lists.drop 1 (lib.lists.remove "" (lib.strings.splitString "\n" (readFile ./home-assistant/windows.csv))));
  secretsYaml = pkgs.writeText "secrets.yaml" ''
    doorbell_password: ${pw.doorbell}
  '';
in
{
  docker = {
    image = "ghcr.io/home-assistant/home-assistant:stable";
    configVolume = "/config";
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
      VERSION = "latest";
    };
    volumes = [
      "/etc/${name}:/config/etc:ro"
      "${secretsYaml}:/config/secrets.yaml:ro"
      "/etc/static:/etc/static:ro"
      "/nix/store:/nix/store:ro"
      "/run/dbus:/run/dbus:ro"
    ];
    extraOptions = [
      "--privileged"
    ];
  };
  extraConfig = {
    environment.etc = {
      "${name}/automation/verify_device_ids.yaml" = {
        source = (pkgs.formats.yaml { }).generate "verify_device_ids.yaml" {
          id = "verify_device_ids";
          alias = "Verify Nix Device ID Map";
          mode = "single";
          triggers =
            [{
              trigger = "homeassistant";
              event = "start";
              id = "setup";
            }];
          actions = lib.lists.flatten (map
            (entity_id:
              let
                device_id = (getAttr entity_id device_ids);
              in
              if (device_id == null) then [ ] else [
                (
                  let
                    notification_id = "nix_device_id_incorrect_${replaceStrings ["."] ["_"] entity_id}";
                  in
                  {
                    "if" = "{{ device_id('${entity_id}') == '${device_id}' }}";
                    "then" = [{
                      action = "persistent_notification.dismiss";
                      data = {
                        inherit notification_id;
                      };
                    }];
                    "else" = [{
                      action = "persistent_notification.create";
                      data = {
                        message = "Entry should be: \"${entity_id}\" = \"{{ device_id('${entity_id}') }}\";";
                        title = "Nix Device ID Map is incorrect for ${entity_id}";
                        inherit notification_id;
                      };
                    }];
                  }
                )
              ]
            )
            (attrNames device_ids));
        };
      };
    }
    //
    listToAttrs
      (lib.lists.flatten (map
        (
          w:
          (if w.opens then [
            {
              name = "${name}/input_boolean/${w.window_open_name}.yaml";
              value = { text = ""; };
            }
          ] else [ ]) ++
          (if w.has_shade then [
            {
              name = "${name}/input_number/${w.target_name}.yaml";
              value = {
                text = ''
                  min: 0
                  max: 100
                '';
              };
            }
            {
              name = "${name}/input_boolean/${w.override_name}.yaml";
              value = { text = "initial: false"; };
            }
            {
              name = "${name}/automation/${w.shade_name}_auto_set.yaml";
              value = {
                source = (pkgs.formats.yaml { }).generate "${w.shade_name}_auto_set.yaml" {
                  alias = "${w.shade_name} auto set";
                  id = "${w.shade_name}_auto_set";
                  mode = "restart";
                  trigger = [
                    {
                      platform = "state";
                      entity_id = [ "input_number.${w.target_name}" ];
                    }
                    {
                      platform = "state";
                      entity_id = [ "input_boolean.${w.override_name}" ];
                      to = "off";
                    }
                  ] ++ (if w.opens then [
                    {
                      platform = "state";
                      entity_id = [ "input_boolean.${w.window_open_name}" ];
                    }
                  ] else [ ]);
                  condition = [
                    {
                      condition = "state";
                      entity_id = "input_boolean.${w.override_name}";
                      state = "off";
                    }
                  ];
                  action = [
                    {
                      variables = {
                        p = if w.opens then "{{ [states('input_number.${w.target_name}') | int, ${toString w.open_limit} if is_state('input_boolean.${w.window_open_name}', 'on') else 0] | max }}" else "{{ states('input_number.${w.target_name}') | int }}";
                      };
                    }
                    {
                      service = "cover.set_cover_position";
                      target = { entity_id = "cover.${w.shade_name}"; };
                      data = { position = "{{ p }}"; };
                    }
                  ];
                };
              };
            }
            {
              name = "${name}/automation/${w.shade_name}_user_set.yaml";
              value = {
                text = ''
                  alias: ${w.shade_name} user set
                  id: ${w.shade_name}_user_set
                  mode: restart
                  trigger:
                    - platform: state
                      entity_id:
                        - cover.${w.shade_name}
                      attribute: current_position
                      for:
                        seconds: 10
                  condition: >-
                    {% if ("current_position" not in trigger.from_state.attributes) or ("current_position" not in trigger.to_state.attributes) %}
                      false
                    {% else %}
                      {{ ([trigger.from_state.attributes.current_position | int, trigger.to_state.attributes.current_position | int, states('input_number.${w.target_name}') | int] | sort)[1] != (trigger.to_state.attributes.current_position | int) }}
                    {% endif %}
                  action:
                    - service: input_boolean.turn_on
                      target:
                        entity_id: input_boolean.${w.override_name}
                '';
              };
            }
            {
              name = "${name}/automation/${w.shade_name}_user_reset.yaml";
              value = {
                text = ''
                  alias: ${w.shade_name} user reset
                  id: ${w.shade_name}_user_reset
                  mode: restart
                  trigger:
                    - platform: state
                      entity_id:
                        - input_boolean.${w.override_name}
                      to: "on"
                      for:
                        hours: 2
                  action:
                    - service: input_boolean.turn_off
                      target:
                        entity_id: input_boolean.${w.override_name}
                '';
              };
            }
          ] else [ ])
        )
        windows))
    //
    listToAttrs (lib.lists.flatten (map
      (
        i: lib.lists.flatten (map
          (
            j: [
              {
                name = "${name}/shell_command/cec_${i.device}_${j.command}.yaml";
                value = {
                  text = "(echo 'tx 1${i.index}:44:${j.code}'; sleep 0.050s; echo 'tx 1${i.index}:45') | nc -uw1 theater-cec 9526";
                };
              }
            ]
          )
          cec_map)
      )
      theater_devices))
    //
    listToAttrs (lib.lists.flatten (map
      (
        i: [
          # { name = "${name}/input_boolean/${i.id}_lights.yaml"; value = { text = ""; }; }
          # { name = "${name}/input_boolean/${i.id}_xfan.yaml"; value = { text = ""; }; }
          # { name = "${name}/input_boolean/${i.id}_health.yaml"; value = { text = ""; }; }
          # { name = "${name}/input_boolean/${i.id}_sleep.yaml"; value = { text = ""; }; }
          # { name = "${name}/input_boolean/${i.id}_powersave.yaml"; value = { text = ""; }; }
          { name = "${name}/input_boolean/${i.id}_eightdegheat.yaml"; value = { text = ""; }; }
          # { name = "${name}/input_boolean/${i.id}_air.yaml"; value = { text = ""; }; }
          {
            name = "${name}/climate/${i.id}.yaml";
            value = {
              text = ''
                platform: gree
                name: ${i.name}
                host: ${i.host}.home.gustafson.me
                port: 7000
                mac: ${i.mac}
                target_temp_step: 1
                encryption_version: 2
                # lights: input_boolean.${i.id}_lights
                # xfan: input_boolean.${i.id}_xfan
                # health: input_boolean.${i.id}_health
                # sleep: input_boolean.${i.id}_sleep
                # powersave: input_boolean.${i.id}_powersave
                eightdegheat: input_boolean.${i.id}_eightdegheat
                # air: input_boolean.${i.id}_air
              '';
            };
          }
        ]
      )
      gree_climate_devices))
    //
    listToAttrs (lib.lists.flatten (map
      (
        k:
        let
          group_id = "${replaceStrings [" "] ["_"] (lib.strings.toLower k)}_light_group";
          entities = (getAttr k light_groups);
          devices = lib.lists.flatten (map (e: if ((getAttr e device_ids) != null) then [ (getAttr e device_ids) ] else [ ]) entities);
        in
        [
          {
            name = "${name}/light/${group_id}.yaml";
            value = {
              source = (pkgs.formats.yaml { }).generate "${group_id}.yaml" {
                platform = "group";
                unique_id = "${group_id}";
                name = "${k} Light Group";
                all = true;
                entities = filter (e: (match ".*_virtual.*" e) == null) entities;
              };
            };
          }
          {
            name = "${name}/automation/${group_id}.yaml";
            value = {
              source = (pkgs.formats.yaml { }).generate "${group_id}.yaml" {
                id = "${group_id}";
                alias = "${k} Light Group";
                mode = "restart";
                triggers =
                  [{
                    trigger = "homeassistant";
                    event = "start";
                    id = "setup";
                  }]
                  ++
                  (map
                    (i: {
                      device_id = i;
                      domain = "zwave_js";
                      type = "event.value_notification.central_scene";
                      property = "scene";
                      property_key = "001";
                      endpoint = 0;
                      command_class = 91;
                      subtype = "Endpoint 0 Scene 001";
                      trigger = "device";
                      value = 3;
                      id = "on";
                    })
                    devices)
                  ++
                  (map
                    (i: {
                      device_id = i;
                      domain = "zwave_js";
                      type = "event.value_notification.central_scene";
                      property = "scene";
                      property_key = "002";
                      endpoint = 0;
                      command_class = 91;
                      subtype = "Endpoint 0 Scene 002";
                      trigger = "device";
                      value = 3;
                      id = "off";
                    })
                    devices);
                actions = [{
                  choose = [
                    {
                      conditions = [{ condition = "trigger"; id = [ "setup" ]; }];
                      sequence = (map
                        (i: {
                          action = "zwave_js.set_config_parameter";
                          data = {
                            device_id = devices;
                          } // i;
                        }) [
                        {
                          parameter = 32; # LED Indicator: Confirm Configuration Change
                          value = 1; # Disable
                        }
                        {
                          parameter = 12; # Double-Tap Upper Paddle Behavior
                          value = 3; # Disable
                        }
                        {
                          parameter = 13; # Scene Control
                          value = 1; # Enable
                        }
                        {
                          parameter = 26; # Local Programming
                          value = 1; # Disable
                        }
                      ]);
                    }
                    {
                      conditions = [{ condition = "trigger"; id = [ "on" ]; }];
                      sequence = [{
                        action = "light.turn_on";
                        data = { brightness_pct = "100"; };
                        target = { entity_id = "light.${group_id}"; };
                      }];
                    }
                    {
                      conditions = [{ condition = "trigger"; id = [ "off" ]; }];
                      sequence = [{
                        action = "light.turn_off";
                        target = { entity_id = "light.${group_id}"; };
                      }];
                    }
                  ];
                }];
              };
            };
          }
        ]
      )
      (attrNames light_groups)));
  };
}
