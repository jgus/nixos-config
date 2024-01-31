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

  environment.etc = let items = [ "x" "y" ]; in
    builtins.listToAttrs
      (lib.lists.flatten (map
        (i:
          [
            {
              name = "home-assistant/${i}.1.yaml";
              value = {
                text = ''
                  ${i} 1
                '';
              };
            }
            {
              name = "home-assistant/${i}.2.yaml";
              value = {
                text = ''
                  ${i} 2
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
        script ui: !include scripts.yaml
        scene ui: !include scenes.yaml
        template ui: !include template.yaml

        amcrest: !include_dir_list  etc/amcrest

        wake_on_lan:

        light:
          - platform: template
            lights: !include_dir_named etc/light/template

        fan:
          - platform: template
            fans: !include_dir_named etc/fan/template

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
