{ config, pkgs, lib, ... }:

let pw = import ./.secrets/passwords.nix;
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
    in
    builtins.listToAttrs
      (lib.lists.flatten (map
        (i:
          [
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
                    action:
                      - service: automation.turn_off
                        data:
                          stop_actions: true
                        target:
                          entity_id: automation.cover_${i}_user_set
                      - service: cover.set_cover_position
                        target:
                          entity_id: cover.${i}
                        data:
                          position: "{{ states('input_number.cover_${i}_auto_target') }}"
                      - service: automation.turn_on
                        target:
                          entity_id: automation.cover_${i}_user_set
                  - alias: cover ${i} user set
                    id: cover_${i}_user_set
                    mode: restart
                    trigger:
                      - platform: state
                        entity_id:
                          - cover.${i}
                        attribute: current_position
                    action:
                      - service: automation.turn_off
                        data:
                          stop_actions: true
                        target:
                          entity_id: automation.cover_${i}_auto_set
                      - delay:
                          hours: 1
                      - service: automation.turn_on
                        target:
                          entity_id: automation.cover_${i}_auto_set
                      - service: automation.trigger
                        target:
                          entity_id: automation.cover_${i}_auto_set
                '';
              };
            }
          ]
        )
        items)) // {
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
      "home-assistant/configuration.yaml".text = ''
        # Loads default set of integrations. Do not remove.
        default_config:

        # Load frontend themes from the themes folder
        frontend:
          themes: !include_dir_merge_named themes

        automation ui: !include automations.yaml
        automation etc: !include_dir_merge_list etc/automation
        script ui: !include scripts.yaml
        scene: !include scenes.yaml
        template: !include template.yaml

        wake_on_lan:

        amcrest: !include_dir_list  etc/amcrest

        input_number: !include_dir_named etc/input_number

        light:
          - platform: template
            lights: !include_dir_named etc/light/template

        fan:
          - platform: template
            fans: !include_dir_named etc/fan/template

        cover:
          - platform: template
            covers: !include_dir_named etc/cover/template

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
            ghcr.io/home-assistant/home-assistant:jgus-dev
        '';
        serviceConfig = {
          Restart = "on-failure";
        };
      };
      # home-assistant-update = {
      #   path = [ pkgs.docker ];
      #   script = ''
      #     if docker pull ghcr.io/home-assistant/home-assistant:stable | grep "Status: Downloaded"
      #     then
      #       systemctl restart home-assistant
      #     fi
      #   '';
      #   serviceConfig = {
      #     Type = "oneshot";
      #   };
      #   startAt = "hourly";
      # };
    };
  };
}
