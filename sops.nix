{ pkgs, ... }:
{
  # sops-nix module is now imported via flake inputs in configuration.nix

  environment = {
    systemPackages = with pkgs; [
      sops
      age
    ];
    sessionVariables = {
      SOPS_AGE_KEY_FILE = "/etc/ssh/age-host-key.txt";
    };
  };

  # https://dl.thalheim.io/
  sops = {
    defaultSopsFile = ./secrets/passwords.yaml;
    age = {
      keyFile = "/etc/ssh/age-host-key.txt";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };
}
