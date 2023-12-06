{ ... }:

let
  machine = import ./machine.nix;
in
{
  time.timeZone = "America/Denver";

  # mkdir .secrets/ssh ; cp /etc/ssh/ssh_host_* .secrets/ssh/
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
    hostName = machine.hostName;
    hostId = machine.hostId;
  };
}
