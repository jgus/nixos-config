{ ... }:
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
        from = "alert@gustafson.me";
        user = "gustafsonme";
        password = (import .secrets/passwords.nix).smtp2go;
      };
    };
  };
}
