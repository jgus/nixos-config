{ pkgs, ... }:
{
  executable = "podman";
  package = pkgs.podman;
  group = "podman";
}
