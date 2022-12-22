{ ... }:

{
  time.timeZone = "America/Denver";

  environment.etc = {
    "ssh/ssh_host_ed25519_key" = {
      source = ./.secrets/ssh/ssh_host_ed25519_key;
      mode = "0600";
    };
    "ssh/ssh_host_ed25519_key.pub" = {
      source = ./.secrets/ssh/ssh_host_ed25519_key.pub;
      mode = "0644";
    };
    "ssh/ssh_host_rsa_key" = {
      source = ./.secrets/ssh/ssh_host_rsa_key;
      mode = "0600";
    };
    "ssh/ssh_host_rsa_key.pub" = {
      source = ./.secrets/ssh/ssh_host_rsa_key.pub;
      mode = "0644";
    };
  };

  networking = {
    hostName = "c1";
    hostId = "04b22318"; # head -c4 /dev/urandom | od -A none -t x4
  };
}
