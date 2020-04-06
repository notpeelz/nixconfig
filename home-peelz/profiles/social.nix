{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.my.social;
in {
  options.my.social = {
    enable = mkEnableOption "Social programs";
  };

  config = mkIf cfg.enable {
    home.packages = (with pkgs; [
      irssi
    ]) ++ (optionals config.my.graphical.enable (with pkgs; [
      hexchat
      discord
    ]));
  };
}
