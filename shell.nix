{
  pkgs ? import <nixpkgs> { },
  hostname,
}:
let
  deployAll =
    if (hostname == "code-server") then ./bin/nixos-deploy-all-c1-2.sh else ./bin/nixos-deploy-all.sh;
in
pkgs.mkShellNoCC {
  buildInputs = with pkgs; [
    (writeScriptBin "nixos-deploy-all" (builtins.readFile deployAll))
    (writeScriptBin "verify-sops-backups" (builtins.readFile ./bin/verify-sops-backups.sh))
    (writeScriptBin "update-images" (builtins.readFile ./bin/update-images.sh))
    git
    sops
    age
    nixos-rebuild
  ];

  shellHook = ''
    echo "direnv shell on ${hostname}"
  '';
}
