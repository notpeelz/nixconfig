{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.my.graphical.xorg;
in {
  options.my.graphical.xorg = {
    autorepeat = {
      delay = mkOption {
        type = types.ints.positive;
        default = 300;
      };
      rate = mkOption {
        type = types.ints.positive;
        default = 50;
      };
    };
    screensaver = {
      enable = mkEnableOption "Automatically turn off the display" // {
        default = true;
      };
      delay = mkOption {
        type = types.ints.positive;
        default = 300;
      };
      dpms = mkEnableOption "Display Power Management Signalling";
    };
    numlock = mkEnableOption "Turn off NumLock by default";
  };

  config = mkIf config.services.xserver.enable {
    services.xserver.displayManager.setupCommands = ''
      ${pkgs.numlockx}/bin/numlockx ${if cfg.numlock then "on" else "off"}
      ${pkgs.xorg.xset}/bin/xset r rate ${toString cfg.autorepeat.delay} ${toString cfg.autorepeat.rate}
      ${if cfg.screensaver.enable then ''
        ${pkgs.xorg.xset}/bin/xset s ${toString cfg.screensaver.delay} \
        ${if cfg.screensaver.dpms then "+dpms" else "-dpms"}
      '' else ''
        ${pkgs.xorg.xset}/bin/xset s off -dpms
      ''}
    '';
  };
}
