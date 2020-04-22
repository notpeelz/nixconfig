{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.my.dev;
in {
  options.my.dev = {
    enable = mkEnableOption "Development";
  };

  config = mkIf cfg.enable {
    programs.wireshark.enable = true;
    programs.wireshark.package = mkIf config.my.graphical.enable pkgs.wireshark-qt;
  };
}
