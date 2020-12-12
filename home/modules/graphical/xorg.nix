{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.my.graphical.xorg;
in {
  options.my.graphical.xorg = {
    enable = mkEnableOption "X-specific settings" // {
      # This is controlled by the host config
      default = false;
      internal = true;
    };
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
  };

  config = mkIf cfg.enable {
    systemd.user.services.x-prefs = {
      Unit = {
        Description = "Set up user preferences for X";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = toString (pkgs.writeShellScript "set-x-prefs" (''
          ${pkgs.xorg.xset}/bin/xset r rate ${toString cfg.autorepeat.delay} ${toString cfg.autorepeat.rate}
          ${if cfg.screensaver.enable then ''
            ${pkgs.xorg.xset}/bin/xset s ${toString cfg.screensaver.delay} \
            ${if cfg.screensaver.dpms then "+dpms" else "-dpms"}
          '' else ''
            ${pkgs.xorg.xset}/bin/xset s off -dpms
          ''}
        ''));
      };
    };
  };
}
