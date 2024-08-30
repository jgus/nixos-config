with builtins;
let
  serviceDir = readDir ./services;
in
args@{ pkgs, lib, ... }:
with (import ./functions.nix) args;
let
  serviceNames = lib.lists.flatten (map (n: if (serviceDir.${n} == "regular" && (lib.strings.hasSuffix ".nix" n) && !(lib.strings.hasPrefix "." n)) then [ (lib.strings.removeSuffix ".nix" n) ] else [ ]) (attrNames serviceDir));
  importService = n:
    let
      i = (import ./services/${n}.nix) args;
    in
    if (isList i) then (map (f: homelabService f) i) else (homelabService ({ name = n; } // i));
in
{
  imports = lib.lists.flatten (map importService serviceNames);
}
