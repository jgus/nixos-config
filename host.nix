let
  machine = import ./machine.nix;
in
{ ... }:
{
  time.timeZone = "America/Denver";

  # Use backup-ssh.sh and restore-ssh.sh to backup/restore keys
  services.openssh.hostKeys = [
    {
      path = "/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
    {
      path = "/etc/ssh/ssh_host_ecdsa_key";
      type = "ecdsa";
    }
    {
      path = "/etc/ssh/ssh_host_rsa_key";
      type = "rsa";
      bits = 4096;
    }
  ];

  networking = {
    hostName = machine.hostName;
    hostId = machine.hostId;
  };
}
