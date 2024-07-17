{ ... }:

{
  environment.etc = {
    ".secrets/dyndns".source = ./.secrets/dyndns;
  };

  services.ddclient = {
    enable = true;
    username = "joshgustafson";
    passwordFile = "/etc/.secrets/dyndns";
    domains = [ "gustafson-home.dyndns.org" ];
  };
}
