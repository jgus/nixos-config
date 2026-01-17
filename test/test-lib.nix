# Test library with assertion helper functions
# Takes lib and lib.ext as inputs

with builtins;

{ lib }:
{
  # Assert two values are equal, with helpful error message on failure
  assertEq = msg: expected: actual:
    if expected == actual then true
    else
      throw "Assertion failed: ${msg}\n  Expected: ${lib.ext.toDebugStr expected}\n  Actual: ${lib.ext.toDebugStr actual}";

  # Assert a value is in a list
  assertIn = msg: needle: haystack:
    if lib.elem needle haystack then true
    else throw "Assertion failed: ${msg}\n  ${toString needle} not found in list";

  # Assert a key exists in an attrs set
  assertHasKey = msg: key: attrs:
    if hasAttr key attrs then true
    else throw "Assertion failed: ${msg}\n  Key '${key}' not found";

  # Assert a value is not null
  assertNotNull = msg: value:
    if value != null then true
    else throw "Assertion failed: ${msg}\n  Value is null but should not be";
}
