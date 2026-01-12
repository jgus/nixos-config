with builtins;
{ lib, pkgs, ... }:
rec {
  # Parse a hex string (1-2 hexits) to integer
  hexToInt = hex:
    let
      hexits = lib.stringToCharacters (lib.strings.toLower hex);
      hexitToInt = c:
        if c == "0" then 0 else if c == "1" then 1 else if c == "2" then 2 else if c == "3" then 3
        else if c == "4" then 4 else if c == "5" then 5 else if c == "6" then 6 else if c == "7" then 7
        else if c == "8" then 8 else if c == "9" then 9 else if c == "a" then 10 else if c == "b" then 11
        else if c == "c" then 12 else if c == "d" then 13 else if c == "e" then 14 else 15;
    in
    if length hexits == 1 then hexitToInt (head hexits)
    else (hexitToInt (head hexits)) * 16 + (hexitToInt (lib.lists.last hexits));

  # Convert MAC address to EUI-64 IPv6 interface identifier (pure Nix implementation)
  # Algorithm: Split MAC, insert ff:fe in middle, flip bit 7 of first octet
  # Takes a prefix argument like "2001:55d:b00b:1::"
  macToIp6 = prefix: mac:
    let
      # Split MAC "aa:bb:cc:dd:ee:ff" into list of hex strings
      octets = lib.splitString ":" mac;
      # Convert to integers
      o = map hexToInt octets;
      # Flip the Universal/Local bit (bit 1, i.e., XOR with 0x02) on first octet
      o0flipped = lib.trivial.bitXor (elemAt o 0) 2;
      # Build the 8 EUI-64 octets: [o0', o1, o2, 0xff, 0xfe, o3, o4, o5]
      eui64 = [ o0flipped (elemAt o 1) (elemAt o 2) 255 254 (elemAt o 3) (elemAt o 4) (elemAt o 5) ];
      # Format as 4 groups of 2 octets each (IPv6 suffix format)
      toHex4 = a: b: lib.strings.toLower (lib.trivial.toHexString (a * 256 + b));
      suffix = lib.concatStringsSep ":" [
        (toHex4 (elemAt eui64 0) (elemAt eui64 1))
        (toHex4 (elemAt eui64 2) (elemAt eui64 3))
        (toHex4 (elemAt eui64 4) (elemAt eui64 5))
        (toHex4 (elemAt eui64 6) (elemAt eui64 7))
      ];
      # Strip trailing colons from prefix (e.g., "2001:55d:b00b:1::" -> "2001:55d:b00b:1")
      prefixBase = lib.strings.removeSuffix "::" prefix;
    in
    # Combine prefix with suffix using single colon
    "${prefixBase}:${suffix}";

  prettyYaml = x: (readFile ((pkgs.formats.yaml { }).generate "yaml" x));
}
