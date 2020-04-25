{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.my.video;
in {
  imports = [
    ./v4l2loopback.nix
  ];

  options.my.video = {
    enable = mkEnableOption "Video and streaming-related programs";
  };

  config = mkIf cfg.enable {
    my.video.v4l2loopback.enable = mkDefault true;
  };
}
