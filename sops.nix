{ pkgs, ... }:
let
  machine = import ./machine.nix;
in
{
  imports =
    let
      # https://github.com/Mic92/sops-nix/commits/master/
      commit = "ea3adcb6d2a000d9a69d0e23cad1f2cacb3a9fbe";
      sha256 = "sha256:1gsjpxl5ffrxxq6gkrcj0smfkn8bhsz98a4whl4663rdz8s4882r";
    in
    [
      "${builtins.fetchTarball {
      url = "https://github.com/Mic92/sops-nix/archive/${commit}.tar.gz";
      inherit sha256;
    }}/modules/sops"
    ];

  environment = {
    systemPackages = with pkgs; [
      sops
      age
    ];
    etc."ssh/age-host-key.txt" = {
      mode = "0400";
      source = pkgs.runCommand "age-host-key.txt"
        {
          buildInputs = [ pkgs.ssh-to-age ];
        } ''
        ssh-to-age -private-key -i ${./.secrets/ssh/${machine.hostName}/ssh_host_ed25519_key} > $out
      '';
    };
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
