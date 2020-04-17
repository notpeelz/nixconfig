{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.my.gaming;
in {
  options.my.gaming = {
    enable = mkEnableOption "Gaming programs";
    ultrawide = mkEnableOption "21:9-specific settings";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      lutris
      # Fixes missing "Show game info" option; NixOS/nixpkgs#80184
      # TODO: make this into an overlay
      (steam.override (self: { extraLibraries = pkgs: [ lsof ]; }))
      multimc
    ];

    my.graphical.wm.bspwm.rules = (optional cfg.ultrawide
    # Force Overwatch (in a Wine virtual desktop) to a 16:9 resolution
    # This is used to fix the aim drifting issue with non-16:9 resolutions
    { name = "Wine:explorer.exe";
      state = "floating";
      center = "on";
      border = "off";
      rectangle = {
        width = 2560;
        height = 1440;
      };
    }) ++ [
      # Fix Overcooked 2 being aligned on the left side of the screen
      { name = "Overcooked2.x86_64";
        center = "on";
      }
      { name = "Steam";
        follow = "off";
        desktop = 8;
      }
    ];

    # FIXME: this gets reset when home-manager restarts the setxkbmap service
    #        and needs to be manually reapplied; see https://github.com/rycee/home-manager/issues/543
    # TODO: combine this into systemd.user.services.setxkbmap.Service
    xsession.initExtra = ''
      # Fix Overwatch (Lutris) detecting RCtrl instead of LCtrl
      # https://bugs.winehq.org/show_bug.cgi?id=45148
      # Fixed in wine >=5.0_rc1 (2019-12-10)
      xmodmap -e "keycode 37 = Control_R NoSymbol Control_R" &
    '';
  };
}
