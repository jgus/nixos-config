{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    python311Full
    python311Packages.pip
  ];
}
