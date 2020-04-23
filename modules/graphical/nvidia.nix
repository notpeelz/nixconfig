{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.my.graphical.nvidia;
in {
  options.my.graphical.nvidia = {
    enable = mkEnableOption "NVIDIA-specific graphical settings";
  };

  config = mkIf cfg.enable {
    # Prevent the NVIDIA sources (binary blobs) from getting GC'd
    system.extraDependencies =
      (map (module: module.src)
        (flatten
          (map (driver: driver.modules)
            config.services.xserver.drivers)));

    services.xserver.videoDrivers = [ "nvidia" ];
    my.users.globalOverrides = {
      # Enable nvidia profile for all users
      my.graphical.nvidia.enable = true;
    };
  };
}
