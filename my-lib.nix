{ pkgs, ... }:
{
  prettyYaml = x: (builtins.readFile ((pkgs.formats.yaml { }).generate "yaml" x));
}
