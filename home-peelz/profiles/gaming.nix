{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.my.gaming;
in {
  options.my.gaming = {
    enable = mkEnableOption "Gaming programs";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      lutris
      # Fixes missing "Show game info" option; NixOS/nixpkgs#80184
      # TODO: make this into an overlay
      (steam.override (self: { extraLibraries = pkgs: [ lsof ]; }))
      multimc
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
