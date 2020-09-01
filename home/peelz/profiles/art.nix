{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.my.art;
in {
  options.my.art = {
    enable = mkEnableOption "Content creation programs";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      gimp
      inkscape
    ] ++ (if config.my.graphical.nvidia.enable then [
      (blender.override (old: {
        cudaSupport = true;
      }))
    ] else [ blender ]);
  };
}
