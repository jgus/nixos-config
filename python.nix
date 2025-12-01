{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    python311
    # python311Packages.pip
  ];
}
