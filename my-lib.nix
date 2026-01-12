with builtins;
{ lib, pkgs, ... }:
{
  # Convert MAC address to EUI-64 IPv6 interface identifier 
  # Takes a prefix argument like "2001:55d:b00b:1::"
  macToIp6 = prefix: mac:
    let
      octets = lib.splitString ":" mac;
      o = map lib.trivial.fromHexString octets;
      # Flip the Universal/Local bit (bit 1, i.e., XOR with 0x02) on first octet
      o0flipped = lib.trivial.bitXor (elemAt o 0) 2;
      eui64 = [ o0flipped (elemAt o 1) (elemAt o 2) 255 254 (elemAt o 3) (elemAt o 4) (elemAt o 5) ];
      toHex4 = a: b: lib.strings.toLower (lib.trivial.toHexString (a * 256 + b));
      suffix = lib.concatStringsSep ":" [
        (toHex4 (elemAt eui64 0) (elemAt eui64 1))
        (toHex4 (elemAt eui64 2) (elemAt eui64 3))
        (toHex4 (elemAt eui64 4) (elemAt eui64 5))
        (toHex4 (elemAt eui64 6) (elemAt eui64 7))
      ];
      prefixBase = lib.strings.removeSuffix "::" prefix;
    in
    "${prefixBase}:${suffix}";

  prettyYaml = x: (readFile ((pkgs.formats.yaml { }).generate "yaml" x));

  # Convert values to string for debugging in test assertions
  toDebugStr = x:
    if isString x then x
    else if isInt x || isBool x then toString x
    else if isList x then toJSON x
    else if isAttrs x then toJSON x
    else toString x;
}
