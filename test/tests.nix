{ lib, ... }:
{
  # Force evaluation of tests by including in assertions
  config.assertions =
    let
      libHomelabTest = import ./lib-homelab-test.nix { inherit lib; };
    in
    [
      {
        assertion = libHomelabTest == null;
        message = "lib.homelab tests failed";
      }
    ];
}
