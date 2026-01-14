{ addresses, config, ... }:
{
  programs.msmtp = {
    enable = true;
    defaults = {
      auth = "on";
      tls = true;
    };
    accounts = {
      default = {
        host = "mail.smtp2go.com";
        port = 587;
        from = "alert@${addresses.network.publicDomain}";
        user = "gustafsonme";
        passwordeval = "cat ${config.sops.secrets.smtp2go.path}";
      };
    };
  };
  sops.secrets.smtp2go = { };
}
