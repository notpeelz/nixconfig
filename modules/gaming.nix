{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.my.gaming;
in {
  options.my.gaming = {
    enable = mkEnableOption "Gaming programs";
  };

  config = mkIf cfg.enable {
    # Open ports in the firewall
    networking.firewall.allowedTCPPorts = [
      # Steam Remote Play
      27036 27037
    ];
    networking.firewall.allowedUDPPorts = [
      # Steam Remote Play
      27031 27036
    ];

    # Enable direct rendering for 32-bit applications (steam, wine, etc.)
    hardware.opengl.driSupport32Bit = true;
  };
}
