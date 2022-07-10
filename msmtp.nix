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
        host = "smtp.gmail.com";
        port = 587;
        from = "joshgstfsn@gmail.com";
        user = "joshgstfsn";
        password = import .secrets/gmail-password.nix;
      };
    };
  };
}
