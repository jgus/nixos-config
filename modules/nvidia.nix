{ config, ... }:
{
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.cudaSupport = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;
  hardware.nvidia.open = false;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
  hardware.nvidia-container-toolkit = {
    enable = true;
    device-name-strategy = "uuid";
  };
}
