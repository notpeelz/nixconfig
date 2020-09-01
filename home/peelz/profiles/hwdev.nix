{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.my.hwdev;
in {
  options.my.hwdev = {
    enable = mkEnableOption "Hardware development";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      audacity
      geda
      pcb
      gerbv
      kicad
      freecad
    ];
  };
}
