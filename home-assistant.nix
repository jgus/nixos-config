{ config, pkgs, lib, ... }:

let
  pw = import ./.secrets/passwords.nix;
  image = "ghcr.io/home-assistant/home-assistant:stable";
in
{
  imports = [ ./docker.nix ];

  users = {
    groups.home-assistant = { gid = 200; };
    users.home-assistant = {
      uid = 200;
      isSystemUser = true;
      group = "home-assistant";
    };
  };

  system.activationScripts = {
    home-assistantSetup.text = ''
      ${pkgs.zfs}/bin/zfs list r/varlib/home-assistant >/dev/null 2>&1 || ( ${pkgs.zfs}/bin/zfs create r/varlib/home-assistant && chown home-assistant:home-assistant /var/lib/home-assistant )
    '';
  };

  networking.firewall.allowedTCPPorts = [ 8123 ];

  environment.etc =
    let
      items = [
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
    in
    builtins.listToAttrs(lib.lists.flatten(map(
      i: [
        {
          name = "home-assistant/input_number/cover_${i}_auto_target.yaml";
          value = {
            text = ''
              min: 0
              max: 100
            '';
          };
        }
        {
          name = "home-assistant/input_boolean/cover_${i}_auto_set_enable.yaml";
          value = { text = "initial: true"; };
        }
        {
          name = "home-assistant/input_boolean/cover_${i}_user_set_enable.yaml";
          value = { text = "initial: true"; };
        }
        {
          name = "home-assistant/automation/cover_${i}.yaml";
          value = {
            text = ''
              - alias: cover ${i} auto set
                id: cover_${i}_auto_set
                mode: restart
                trigger:
                  - platform: state
                    entity_id:
                      - input_number.cover_${i}_auto_target
                  - platform: state
                    entity_id:
                      - input_boolean.cover_${i}_auto_set_enable
                    to: "on"
                condition:
                  - condition: state
                    entity_id: input_boolean.cover_${i}_auto_set_enable
                    state: "on"
                action:
                  - service: input_boolean.turn_off
                    target:
                      entity_id: input_boolean.cover_${i}_user_set_enable
                  - wait_template: "{{ is_state('input_boolean.cover_${i}_user_set_enable', 'off') }}"
                  - service: cover.set_cover_position
                    target:
                      entity_id: cover.${i}
                    data:
                      position: "{{ states('input_number.cover_${i}_auto_target') }}"
                  - wait_template: "{{ state_attr('cover.${i}', 'current_position') == states('input_number.cover_${i}_auto_target') | int }}"
                    timeout: "00:01:00"
                  - service: input_boolean.turn_on
                    target:
                      entity_id: input_boolean.cover_${i}_user_set_enable
              - alias: cover ${i} user set
                id: cover_${i}_user_set
                mode: restart
                trigger:
                  - platform: state
                    entity_id:
                      - cover.${i}
                    attribute: current_position
                condition:
                  - condition: state
                    entity_id: input_boolean.cover_${i}_user_set_enable
                    state: "on"
                action:
                  - service: input_boolean.turn_off
                    target:
                      entity_id: input_boolean.cover_${i}_auto_set_enable
                  - delay:
                      hours: 2
                  - service: input_boolean.turn_on
                    target:
                      entity_id: input_boolean.cover_${i}_auto_set_enable
            '';
          };
        }
      ]
    ) items)) //
    builtins.listToAttrs(lib.lists.flatten(map(
      i: lib.lists.flatten(map(
        j: [
          {
            name = "home-assistant/shell_command/cec_${i.device}_${j.command}.yaml";
            value = {
              text = "(echo 'tx 1${i.index}:44:${j.code}'; sleep 0.050s; echo 'tx 1${i.index}:45') | nc -uw1 theater-cec 9526";
            };
          }
        ]
      ) cec_map)
    ) theater_devices)) //
    {
      "home-assistant/automation/Shades.yaml".text = ''
        - alias: Shades
          id: shades
          mode: single
          trace:
            stored_traces: 100
          trigger:
            - platform: sun
              event: sunrise
              id: sun_rise
            - platform: sun
              event: sunset
              id: sun_set
            - platform: state
              entity_id:
                - sensor.solar_shade_target
          condition:
            - condition: or
              conditions:
                - condition: trigger
                  id:
                    - sun_rise
                - condition: trigger
                  id:
                    - sun_set
                - condition: sun
                  before: sunset
                  after: sunrise
          action:
            - variables:
                p: "{{ states('sensor.solar_shade_target') | int }}"
                north_shade_ids:
                  - input_number.cover_loft_shade_1_auto_target
                  - input_number.cover_loft_shade_2_auto_target
                  - input_number.cover_loft_shade_3_auto_target
                  - input_number.cover_office_shade_3_auto_target
                  - input_number.cover_office_shade_4_auto_target
                  - input_number.cover_office_shade_5_auto_target
                east_shade_ids:
                  - input_number.cover_basement_living_room_shade_1_auto_target
                  - input_number.cover_basement_living_room_shade_2_auto_target
                  - input_number.cover_dining_room_shade_1_auto_target
                  - input_number.cover_dining_room_shade_2_auto_target
                  - input_number.cover_dining_room_upper_shade_auto_target
                  - input_number.cover_great_room_lower_left_shade_auto_target
                  - input_number.cover_great_room_lower_right_shade_auto_target
                  - input_number.cover_great_room_upper_left_shade_auto_target
                  - input_number.cover_great_room_upper_right_shade_auto_target
                  - input_number.cover_kitchen_shade_1_auto_target
                  - input_number.cover_kitchen_shade_2_auto_target
                  - input_number.cover_kitchen_shade_3_auto_target
                  - input_number.cover_loft_shade_4_auto_target
                south_shade_ids: []
                west_shade_ids:
                  - input_number.cover_craft_room_shade_1_auto_target
                  - input_number.cover_craft_room_shade_2_auto_target
                  - input_number.cover_music_room_shade_1_auto_target
                  - input_number.cover_music_room_shade_2_auto_target
                  - input_number.cover_office_shade_1_auto_target
                  - input_number.cover_office_shade_2_auto_target
                  - input_number.cover_study_shade_1_auto_target
                  - input_number.cover_study_shade_2_auto_target
                  - input_number.cover_toy_room_shade_1_auto_target
                  - input_number.cover_toy_room_shade_2_auto_target
                  - input_number.cover_toy_room_shade_3_auto_target
            - choose:
                - alias: Open at sunrise
                  conditions:
                    - condition: trigger
                      id:
                        - sun_rise
                  sequence:
                    - repeat:
                        for_each:
                          - "{{ north_shade_ids }}"
                          - "{{ west_shade_ids }}"
                        sequence:
                          - service: input_number.set_value
                            data:
                              value: 100
                            target:
                              entity_id: "{{ repeat.item }}"
                - alias: Close at sunset
                  conditions:
                    - condition: trigger
                      id:
                        - sun_set
                  sequence:
                    - repeat:
                        for_each:
                          - "{{ north_shade_ids }}"
                          - "{{ east_shade_ids }}"
                          - "{{ south_shade_ids }}"
                          - "{{ west_shade_ids }}"
                        sequence:
                          - service: input_number.set_value
                            data:
                              value: 0
                            target:
                              entity_id: "{{ repeat.item }}"
                - alias: Morning program
                  conditions:
                    - condition: state
                      entity_id: sun.sun
                      attribute: rising
                      state: true
                  sequence:
                    - repeat:
                        for_each:
                          - "{{ east_shade_ids }}"
                          - "{{ south_shade_ids }}"
                        sequence:
                          - service: input_number.set_value
                            data:
                              value: "{{ p }}"
                            target:
                              entity_id: "{{ repeat.item }}"
                - alias: Afternoon program
                  conditions:
                    - condition: state
                      entity_id: sun.sun
                      attribute: rising
                      state: false
                  sequence:
                    - repeat:
                        for_each:
                          - "{{ south_shade_ids }}"
                          - "{{ west_shade_ids }}"
                        sequence:
                          - service: input_number.set_value
                            data:
                              value: "{{ p }}"
                            target:
                              entity_id: "{{ repeat.item }}"
      '';
      "home-assistant/automation/Bedroom_Shades.yaml".text = ''
        - alias: Bedroom Shades
          id: bedroom_shades
          mode: single
          trace:
            stored_traces: 100
          trigger:
            - platform: sun
              event: sunrise
              id: sun_rise
            - platform: sun
              event: sunset
              id: sun_set
            - platform: time
              at: "10:00:00"
              id: daytime
          action:
            - variables:
                bedroom_shade_ids:
                  - input_number.cover_basement_east_bedroom_shade_auto_target
                  - input_number.cover_basement_master_bedroom_shade_1_auto_target
                  - input_number.cover_basement_master_bedroom_shade_2_auto_target
                  - input_number.cover_basement_west_bedroom_shade_auto_target
                  - input_number.cover_boy_room_shade_1_auto_target
                  - input_number.cover_boy_room_shade_2_auto_target
                  - input_number.cover_boy_room_shade_3_auto_target
                  - input_number.cover_boy_room_shade_4_auto_target
                  - input_number.cover_boy_room_shade_5_auto_target
                  - input_number.cover_eden_hope_room_shade_1_auto_target
                  - input_number.cover_eden_hope_room_shade_2_auto_target
                  - input_number.cover_kayleigh_lyra_room_shade_1_auto_target
                  - input_number.cover_kayleigh_lyra_room_shade_2_auto_target
                  - input_number.cover_kayleigh_lyra_room_shade_3_auto_target
                  - input_number.cover_master_bedroom_shade_1_auto_target
                  - input_number.cover_master_bedroom_shade_2_auto_target
                  - input_number.cover_master_bedroom_shade_3_auto_target
                  - input_number.cover_master_bedroom_shade_4_auto_target
                  - input_number.cover_master_bedroom_shade_5_auto_target
            - choose:
                - alias: Crack open at sunrise
                  conditions:
                    - condition: trigger
                      id:
                        - sun_rise
                  sequence:
                    - repeat:
                        for_each: "{{ bedroom_shade_ids }}"
                        sequence:
                          - service: input_number.set_value
                            data:
                              value: 20
                            target:
                              entity_id: "{{ repeat.item }}"
                - alias: Open all the way in late morning
                  conditions:
                    - condition: trigger
                      id:
                        - daytime
                  sequence:
                    - repeat:
                        for_each: "{{ bedroom_shade_ids }}"
                        sequence:
                          - service: input_number.set_value
                            data:
                              value: 100
                            target:
                              entity_id: "{{ repeat.item }}"
                - alias: Close at sunset
                  conditions:
                    - condition: trigger
                      id:
                        - sun_set
                  sequence:
                    - repeat:
                        for_each: "{{ bedroom_shade_ids }}"
                        sequence:
                          - service: input_number.set_value
                            data:
                              value: 0
                            target:
                              entity_id: "{{ repeat.item }}"
      '';
      "home-assistant/input_boolean/server_climate_lights.yaml".text = "initial: true";
      "home-assistant/input_boolean/server_climate_xfan.yaml".text = "initial: true";
      "home-assistant/input_boolean/server_climate_health.yaml".text = "initial: true";
      "home-assistant/input_boolean/server_climate_sleep.yaml".text = "initial: true";
      "home-assistant/input_boolean/server_climate_powersave.yaml".text = "initial: true";
      "home-assistant/input_boolean/server_climate_eightdegheat.yaml".text = "initial: true";
      "home-assistant/input_boolean/server_climate_air.yaml".text = "initial: true";
      "home-assistant/climate/server_climate.yaml".text = ''
        platform: gree
        name: Server Climate
        host: server-climate.home.gustafson.me
        port: 7000
        mac: 94:24:b8:6c:0f:41
        target_temp_step: 1
        lights: input_boolean.server_climate_lights
        xfan: input_boolean.server_climate_xfan
        health: input_boolean.server_climate_health
        sleep: input_boolean.server_climate_sleep
        powersave: input_boolean.server_climate_powersave
        eightdegheat: input_boolean.server_climate_eightdegheat
        air: input_boolean.server_climate_air
      '';
      "home-assistant/input_boolean/theater_climate_lights.yaml".text = "initial: true";
      "home-assistant/input_boolean/theater_climate_xfan.yaml".text = "initial: true";
      "home-assistant/input_boolean/theater_climate_health.yaml".text = "initial: true";
      "home-assistant/input_boolean/theater_climate_sleep.yaml".text = "initial: true";
      "home-assistant/input_boolean/theater_climate_powersave.yaml".text = "initial: true";
      "home-assistant/input_boolean/theater_climate_eightdegheat.yaml".text = "initial: true";
      "home-assistant/input_boolean/theater_climate_air.yaml".text = "initial: true";
      "home-assistant/climate/theater_climate.yaml".text = ''
        platform: gree
        name: Theater Climate
        host: theater-climate.home.gustafson.me
        port: 7000
        mac: 94:24:b8:6c:10:13
        target_temp_step: 1
        lights: input_boolean.theater_climate_lights
        xfan: input_boolean.theater_climate_xfan
        health: input_boolean.theater_climate_health
        sleep: input_boolean.theater_climate_sleep
        powersave: input_boolean.theater_climate_powersave
        eightdegheat: input_boolean.theater_climate_eightdegheat
        air: input_boolean.theater_climate_air
      '';
      "home-assistant/input_boolean/workshop_climate_lights.yaml".text = "initial: true";
      "home-assistant/input_boolean/workshop_climate_xfan.yaml".text = "initial: true";
      "home-assistant/input_boolean/workshop_climate_health.yaml".text = "initial: true";
      "home-assistant/input_boolean/workshop_climate_sleep.yaml".text = "initial: true";
      "home-assistant/input_boolean/workshop_climate_powersave.yaml".text = "initial: true";
      "home-assistant/input_boolean/workshop_climate_eightdegheat.yaml".text = "initial: true";
      "home-assistant/input_boolean/workshop_climate_air.yaml".text = "initial: true";
      "home-assistant/climate/workshop_climate.yaml".text = ''
        platform: gree
        name: Workshop Climate
        host: workshop-climate.home.gustafson.me
        port: 7000
        mac: 94:24:b8:6d:47:92
        target_temp_step: 1
        lights: input_boolean.workshop_climate_lights
        xfan: input_boolean.workshop_climate_xfan
        health: input_boolean.workshop_climate_health
        sleep: input_boolean.workshop_climate_sleep
        powersave: input_boolean.workshop_climate_powersave
        eightdegheat: input_boolean.workshop_climate_eightdegheat
        air: input_boolean.workshop_climate_air
      '';
      "home-assistant/amcrest/front_doorbell.yaml".text = ''
        name: "Front Doorbell"
        host: doorbell-front.home.gustafson.me
        username: admin
        password: ${pw.doorbell}
      '';
      "home-assistant/amcrest/basement_doorbell.yaml".text = ''
        name: "Basement Doorbell"
        host: doorbell-basement.home.gustafson.me
        username: admin
        password: ${pw.doorbell}
      '';
      "home-assistant/light/template/range_hood_light.yaml".text = ''
        unique_id: range_hood_light
        friendly_name: "Range Hood Light"
        level_template: "{{ { 'Off': 0, 'Dim': 127, 'High': 255 }[states('select.range_hood_light_level')] }}"
        value_template: "{{ states('select.range_hood_light_level') != 'Off' }}"
        turn_on:
          service: select.select_option
          target:
            entity_id: select.range_hood_light_level
          data:
            option: >-
              {%if not brightness %} High {%elif brightness < 64 %} Off {%elif brightness < 192 %} Dim {%else%} High {%endif%}
        turn_off:
          service: select.select_option
          target:
            entity_id: select.range_hood_light_level
          data:
            option: 'Off'
        set_level:
          service: select.select_option
          target:
            entity_id: select.range_hood_light_level
          data:
            option: >-
              {%if not brightness %} High {%elif brightness < 64 %} Off {%elif brightness < 192 %} Dim {%else%} High {%endif%}
      '';
      "home-assistant/fan/template/range_hood_fan.yaml".text = ''
        unique_id: range_hood_fan
        friendly_name: "Range Hood Fan"
        value_template: "{{ states('select.range_hood_fan_speed') }}"
        percentage_template: "{{ { 'Off': 0, 'Low': 25, 'Medium': 50, 'High': 75, 'Boost': 100 }[states('select.range_hood_fan_speed')] }}"
        turn_on:
          if:
            - condition: template
              value_template: "{{ not has_value('select.range_hood_fan_speed') or is_state('select.range_hood_fan_speed', 'Off') }}"
          then:
            - service: select.select_option
              target:
                entity_id: select.range_hood_fan_speed
              data:
                option: Low
        turn_off:
          service: select.select_option
          target:
            entity_id: select.range_hood_fan_speed
          data:
            option: 'Off'
        set_percentage:
          service: select.select_option
          target:
            entity_id: select.range_hood_fan_speed
          data:
            option: "{{ { 0: 'Off', 1: 'Low', 2: 'Medium', 3: 'High', 4: 'Boost' }[percentage / 25.0 | round | int] }}"
        speed_count: 4
      '';
      "home-assistant/media_player/theater_bluray_status.yaml".text = ''
        platform: panasonic_bluray
        host: theater-bluray.home.gustafson.me
      '';
      "home-assistant/input_select/theater_bluray_target_state.yaml".text = ''
        options:
          - "off"
          - idle
          - playing
      '';
      "home-assistant/automation/theater_bluray_state_update.yaml".text = ''
        - alias: Theater Blu-Ray State Update
          id: theater_bluray_state_update
          mode: queued
          trigger:
            - platform: state
              entity_id:
                - media_player.panasonic_blu_ray
              to: null
          condition:
            - condition: not
              conditions:
                - condition: state
                  entity_id: input_select.theater_bluray_target_state
                  state: "off"
          action:
            - service: input_select.select_option
              target:
                entity_id: input_select.theater_bluray_target_state
              data:
                option: >
                  {% if is_state('media_player.panasonic_blu_ray', 'playing') -%}
                    playing
                  {%- else -%}
                    idle
                  {%- endif %}
      '';
      # "home-assistant/script/theater_bluray.yaml".text = ''
      # '';
      "home-assistant/media_player/theater_bluray.yaml".text = ''
        platform: universal
        name: "Theater Blu-Ray"
        unique_id: theater_bluray
        device_class: tv
        children:
          - media_player.panasonic_blu_ray
        state_template: "{{ states('input_select.theater_bluray_target_state') }}"
        commands:
          turn_off:
            service: script.theater_bluray
            data:
              action: turn_off
          turn_on:
            service: script.theater_bluray
            data:
              action: turn_on
          media_play:
            service: script.theater_bluray
            data:
              action: media_play
          media_pause:
            service: script.theater_bluray
            data:
              action: media_pause
          media_play_pause:
            service: script.theater_bluray
            data:
              action: media_play_pause
          media_stop:
            service: script.theater_bluray
            data:
              action: media_stop
          media_next_track:
            service: script.theater_bluray
            data:
              action: media_next_track
          media_previous_track:
            service: script.theater_bluray
            data:
              action: media_previous_track
      '';
      "home-assistant/media_player/theater_shield.yaml".text = ''
        platform: universal
        name: "Theater Shield"
        unique_id: theater_shield
        device_class: tv
        children:
          - media_player.theater_shield_remote
          - media_player.theater_shield_cast
        browse_media_entity: media_player.theater_shield_cast
        state_template: >
          {% if is_state('media_player.theater_shield_remote', 'off') -%}
            off
          {%- elif is_state('media_player.theater_shield_cast', 'off') -%}
            idle
          {%- else -%}
            {{ states('media_player.theater_shield_cast') }}
          {%- endif %}
        commands:
          turn_off:
            service: media_player.turn_off
            target:
              entity_id: media_player.theater_shield_remote
          turn_on:
            service: media_player.turn_on
            target:
              entity_id: media_player.theater_shield_remote
      '';
      # "home-assistant/script/theater.yaml".text = ''
      # '';
      "home-assistant/media_player/theater.yaml".text = ''
        platform: universal
        name: "Theater"
        unique_id: theater
        device_class: tv
        children:
          - media_player.theater_shield
          - media_player.theater_bluray
          - media_player.theater_preamp_zone_1
        active_child_template: >-
          {% set is_shield = is_state('input_select.theater_activity', ['Plex', 'YouTube', 'Shield']) and not is_state('media_player.theater_shield', 'off') %}
          {% set is_bluray = is_state('input_select.theater_activity', ['Blu-Ray']) and not is_state('media_player.theater_bluray', 'off') %}
          {{ 'media_player.theater_shield' if is_shield else 'media_player.theater_bluray' if is_bluray else 'media_player.theater_preamp_zone_1' }}
        browse_media_entity: media_player.theater_shield
        state_template: >-
          {% set is_shield = is_state('input_select.theater_activity', ['Plex', 'YouTube', 'Shield']) and not is_state('media_player.theater_shield', 'off') %}
          {% set is_bluray = is_state('input_select.theater_activity', ['Blu-Ray']) and not is_state('media_player.theater_bluray', 'off') %}
          {% set id = 'media_player.theater_shield' if is_shield else 'media_player.theater_bluray' if is_bluray else 'media_player.theater_preamp_zone_1' %}
          {{ states(id) }}
        commands:
          turn_off:
            service: script.theater
            data:
              action: turn_off
          turn_on:
            service: script.theater
            data:
              action: turn_on
          select_source:
            service: script.theater
            data:
              action: select_source
              source: "{{ source }}"
          volume_set:
            service: media_player.volume_set
            target:
              entity_id: media_player.theater_preamp_zone_1
            data:
              volume_level: "{{ volume_level }}"
          volume_up:
            service: media_player.volume_up
            target:
              entity_id: media_player.theater_preamp_zone_1
          volume_down:
            service: media_player.volume_down
            target:
              entity_id: media_player.theater_preamp_zone_1
          volume_mute:
            service: media_player.volume_mute
            target:
              entity_id: media_player.theater_preamp_zone_1
            data:
              is_volume_muted: "{{ not state_attr('media_player.theater_preamp_zone_1', 'is_volume_muted') }}"
          select_sound_mode:
            service: media_player.select_sound_mode
            target:
              entity_id: media_player.theater_preamp_zone_1
            data:
              sound_mode: "{{ sound_mode }}"
        attributes:
          source: input_select.theater_activity
          source_list: input_select.theater_activity|options
          is_volume_muted: media_player.theater_preamp_zone_1|is_volume_muted
          volume_level: media_player.theater_preamp_zone_1|volume_level
          sound_mode: media_player.theater_preamp_zone_1|sound_mode
          sound_mode_raw: media_player.theater_preamp_zone_1|sound_mode_raw
          sound_mode_list: media_player.theater_preamp_zone_1|sound_mode_list
      '';
      "home-assistant/configuration.yaml".text = ''
        # Loads default set of integrations. Do not remove.
        default_config:

        # Load frontend themes from the themes folder
        frontend:
          themes: !include_dir_merge_named themes

        automation ui: !include automations.yaml
        automation etc: !include_dir_merge_list etc/automation
        script ui: !include scripts.yaml
        script etc: !include_dir_merge_list etc/script
        scene: !include scenes.yaml
        template: !include template.yaml

        wake_on_lan:

        input_number: !include_dir_named etc/input_number
        input_boolean: !include_dir_named etc/input_boolean
        input_select: !include_dir_named etc/input_select

        light:
          - platform: template
            lights: !include_dir_named etc/light/template

        fan:
          - platform: template
            fans: !include_dir_named etc/fan/template

        cover:
          - platform: template
            covers: !include_dir_named etc/cover/template

        media_player: !include_dir_list  etc/media_player

        climate: !include_dir_list  etc/climate

        amcrest: !include_dir_list  etc/amcrest

        shell_command: !include_dir_named etc/shell_command

        # lock:
        #   - platform: template
        #     name: Balcony South Lock
        #     unique_id: balcony_south_lock
        #     value_template: "{{ is_state('binary_sensor.balcony_south_lock_phys_current_status_of_the_bolt', 'off') }}"
        #     lock:
        #       service: lock.lock
        #       target:
        #         entity_id: lock.balcony_south_lock_phys
        #     unlock:
        #       service: lock.unlock
        #       target:
        #         entity_id: lock.balcony_south_lock_phys
      '';
    };

  systemd = {
    services = {
      home-assistant = {
        enable = true;
        description = "Home Assistant";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = [ pkgs.docker ];
        script = ''
          docker container stop home-assistant >/dev/null 2>&1 || true ; \
          docker container rm -f home-assistant >/dev/null 2>&1 || true ; \
          docker run --rm --name home-assistant \
            --privileged \
            --net host \
            -e PUID="$(id -u home-assistant)" \
            -e PGID="$(id -g home-assistant)" \
            -e TZ="$(timedatectl show -p Timezone --value)" \
            -e VERSION=latest \
            -v /var/lib/home-assistant:/config \
            -v /etc/home-assistant:/config/etc:ro \
            -v /etc/home-assistant/configuration.yaml:/config/configuration.yaml:ro \
            -v "$(readlink -f /etc/static)":/etc/static:ro \
            -v /nix/store:/nix/store:ro \
            -v /run/dbus:/run/dbus:ro \
            ${image}
        '';
        serviceConfig = {
          Restart = "no";
        };
      };
      home-assistant-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull ${image} | grep "Status: Downloaded"
          then
            systemctl restart home-assistant
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
