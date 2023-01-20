{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    python310Full
    python310Packages.pip
  ];
}
