{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.my.graphical.nvidia;
in {
  options.my.graphical.nvidia = {
    enable = mkEnableOption "NVIDIA-specific settings";
  };

  config = mkIf cfg.enable {
    # Nvidia-specific settings
    xsession.initExtra = mkIf config.xsession.enable ''
      # Disable OpenGL 'Sync to VBlank'
      nvidia-settings -a 'SyncToVBlank=0' &

      # Disable OpenGL 'Allow Flipping'
      nvidia-settings -a 'AllowFlipping=0' &
    '';
  };
}
