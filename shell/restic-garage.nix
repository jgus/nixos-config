with (import <nixpkgs> { });
let
  secretDir = "/etc/nixos/.secrets/restic/garage";
in
mkShell {
  buildInputs = [
    restic
  ];
  shellHook = ''
    export $(cat ${secretDir}/env | xargs)
    export RESTIC_PASSWORD_FILE=${secretDir}/password
    export RESTIC_REPOSITORY=$(cat ${secretDir}/repository)
  '';
}
