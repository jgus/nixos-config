{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    dyndnsc
  ];

  environment.etc = {
    ".secrets/dyndnsc.conf".source = .secrets/dyndnsc.conf;
  };

  systemd = {
    services = {
      update-ddns = {
        path = [ pkgs.dyndnsc ];
        script = "dyndnsc -v --config /etc/.secrets/dyndnsc.conf";
        serviceConfig = {
          Type = "oneshot";
        };
        startAt = "hourly";
      };
    };
  };
}
