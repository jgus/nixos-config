with builtins;
{ config, lib, machine, pkgs, self, ... }:
{
  system.nixos.label =
    let
      buildDateTime = lib.strings.removeSuffix "\n" (readFile (pkgs.runCommand "build-date"
        {
          nativeBuildInputs = [ pkgs.tzdata ];
        }
        ''
          TZ=${config.time.timeZone} TZDIR="${pkgs.tzdata}/share/zoneinfo" date "+%Y-%m-%d_%H:%M_%Z" -d @${toString (self.lastModified or 0)} > $out
        ''));
      gitHash = self.shortRev or self.dirtyShortRev or "unknown";
    in
    lib.concatStringsSep "__" [
      buildDateTime
      gitHash
      config.networking.hostName
    ];
}
