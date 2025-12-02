{ config, ... }:
{
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.cudaSupport = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  hardware.nvidia.open = false;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
  hardware.nvidia-container-toolkit = {
    enable = true;
    # mount-nvidia-docker-1-directories = true;
    # mount-nvidia-executables = true;
    # mounts = [
    #   {
    #     hostPath = "/run/opengl-driver/lib/libcuda.so";
    #     containerPath = "/usr/lib/libcuda.so";
    #   }
    # ];
  };
  # virtualisation.docker.daemon.settings.features.cdi = true;
  virtualisation.docker.enableNvidia = true;
}
