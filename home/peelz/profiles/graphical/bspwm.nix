{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.my.graphical.wm.bspwm;

  mkToggleOption = opts: (mkOption {
    type = types.nullOr (types.enum [ "on" "off" ]);
    default = null;
  }) // opts;

  rectangleRuleSubmodule = types.submodule {
    options = {
      width = mkOption {
        type = types.ints.unsigned;
      };
      height = mkOption {
        type = types.ints.unsigned;
      };
      x = mkOption {
        type = types.int;
        default = 0;
      };
      y = mkOption {
        type = types.int;
        default = 0;
      };
      _tostring = mkOption {
        internal = true;
        type = types.unspecified;
        default = self:
          "${toString self.width}x${toString self.height}+${toString self.x}+${toString self.y}";
      };
    };
  };

  ruleSubmodule = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
      };
      border = mkToggleOption {};
      center = mkToggleOption {};
      focus = mkToggleOption {};
      follow = mkToggleOption {};
      hidden = mkToggleOption {};
      locked = mkToggleOption {};
      manage = mkToggleOption {};
      marked = mkToggleOption {};
      private = mkToggleOption {};
      sticky = mkToggleOption {};
      split_dir = mkOption {
        type = types.nullOr (types.enum [ "east" "north" "south" "west" ]);
        default = null;
      };
      split_ratio = mkOption {
        type = types.nullOr types.float;
        default = null;
      };
      state = mkOption {
        type = types.nullOr (types.enum [
          "floating"
          "fullscreen"
          "pseudo_tiled"
          "tiled"
        ]);
        default = null;
      };
      rectangle = mkOption {
        type = types.nullOr rectangleRuleSubmodule;
        default = null;
      };
      layer = mkOption {
        type = types.nullOr (types.enum [ "above" "below" "normal" ]);
        default = null;
      };
      node = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      desktop = mkOption {
        type = types.nullOr (types.either types.str types.int);
        default = null;
      };
      monitor = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
    };
  };
in {
  options.my.graphical.wm.bspwm = {
    enable = mkEnableOption "BSPWM window manager";
    monitors.primary = mkOption {
      type = types.str;
      default = null;
    };
    monitors.secondary = mkOption {
      type = types.str;
      default = null;
    };
    block_fullscreen = mkOption {
      type = types.bool;
      default = true;
    };
    split_ratio = mkOption {
      type = types.float;
      default = 0.5;
    };
    automatic_scheme = mkOption {
      type = types.enum [ "longest_side" "alternate" "spiral" ];
      default = "alternate";
    };
    window_gap = mkOption {
      type = types.ints.unsigned;
      default = 12;
    };
    border_width = mkOption {
      type = types.ints.unsigned;
      default = 4;
    };
    colors.normal = mkOption {
      type = types.str;
      default = "#30302f";
    };
    colors.active = mkOption {
      type = types.str;
      default = "#9e8e7e";
    };
    colors.focused = mkOption {
      type = types.str;
      default = "#906ef5";
    };
    rules = mkOption {
      type = types.listOf ruleSubmodule;
      default = [ ];
    };
  };

  config = mkIf cfg.enable (let
    wmPkgs = with pkgs.pkgs-unstable; {
      inherit (pkgs.pkgs-unstable)
        bspwm
        sxhkd # TODO: put this in its own module
        nitrogen;
    };
  in {
    home.packages = attrValues wmPkgs;

    # X Session
    xsession.enable = true;
    xsession.initExtra = ''
      # Restore wallpaper
      ${wmPkgs.nitrogen}/bin/nitrogen --restore &
    '';

    # TODO: delegate xidlehook options to my.graphical.xidlehook
    # ${pkgs.xidlehook}/bin/xidlehook --timer primary 320 '${pkgs.dm-tool}/bin/dm-tool lock' \'\'

    # Set up window manager
    xsession.windowManager.command = let
      bspwm = "${wmPkgs.bspwm}/bin/bspwm";
      bspc = "${wmPkgs.bspwm}/bin/bspc";
      bspwmrc = pkgs.writeShellScript "bspwmrc" (concatStringsSep "\n" [
        # Monitor and desktop configuration
        ''
          ${bspc} config remove_disabled_monitors true
          ${bspc} config remove_unplugged_monitors true

          # Create 10 desktops per monitor
          ${bspc} monitor ${escapeShellArg cfg.monitors.primary} -d {0..9}
          ${bspc} monitor ${escapeShellArg cfg.monitors.secondary} -d {10..19}

          # https://github.com/baskerville/bspwm/issues/679#issuecomment-315874130
          function enforce_monitor_position() {
            MON_ID="$(${bspc} query -M --names -m "$1")"
            MON_POS="$2"

            [[ $(${bspc} query -M --names -m "$MON_POS") != "$MON_ID" ]] \
              && ${bspc} monitor "$MON_POS" -s "$MON_ID"

            (
              ${bspc} subscribe monitor_swap | while read msg; do
                [[ $(${bspc} query -M --names -m "$MON_POS") != "$MON_ID" ]] \
                  && ${bspc} monitor "$MON_POS" -s "$MON_ID"
              done &
            )
          }

          # Force main monitor to have the 1st desktop
          enforce_monitor_position ${escapeShellArg cfg.monitors.primary} '^1'
        ''

        # General settings
        ''
          ${bspc} config ignore_ewmh_fullscreen ${escapeShellArg cfg.block_fullscreen}
          ${bspc} config automatic_scheme ${escapeShellArg cfg.automatic_scheme}
          ${bspc} config split_ratio ${escapeShellArg cfg.split_ratio}
          ${bspc} config borderless_monocle true
          ${bspc} config gapless_monocle true

          # Reduce the lag when resizing
          ${bspc} config pointer_motion_interval 30
        ''

        # Aesthetics
        ''
          ${bspc} config normal_border_color ${escapeShellArg cfg.colors.normal}
          ${bspc} config active_border_color ${escapeShellArg cfg.colors.active}
          ${bspc} config focused_border_color ${escapeShellArg cfg.colors.focused}
          ${bspc} config border_width ${escapeShellArg cfg.border_width}
          ${bspc} config window_gap ${escapeShellArg cfg.window_gap}
        ''

        # Rules
        (let
         formatAttrs = rule:
          concatStringsSep " " (attrValues
            (mapAttrs
              (n: v:
                if isAttrs v && hasAttr "_tostring" v
                then "${n}=${v._tostring v}" else "${n}=${toString v}")
              (filterAttrs
                (n: v: v != null && n != "name" && !(hasPrefix "_" n))
                rule)));
         formatRule = rule:
           "${bspc} rule -a ${rule.name} ${formatAttrs rule}";
         rules = concatStringsSep "\n"
           (map formatRule cfg.rules);
        in rules)

        # Misc
        ''
          # Fix Java GUI issues
          export _JAVA_AWT_WM_NONREPARENTING=1
          ${bspc} rule -a sun-awt-X11-XDialogPeer state=floating

          # Adopt previous windows
          ${bspc} wm --adopt-orphans

          # TODO: put this in its own module
          BSPWM_GAP=${escapeShellArg cfg.window_gap} SXHKD_SHELL=bash sxhkd -m -1 -c ~/.sxhkdrc &
        ''
      ]);
    in ''
      # TODO: put this in a user service
      # TODO: support restarting/reloading config
      ${bspwm} -c ${bspwmrc}
    '';

    # Compositor
    # FIXME: compton is deprecated and being replaced by picom with NixOS 20.03
    services.compton = {
      enable = true;
      package = pkgs.writeShellScriptBin "compton" ''
        ${pkgs.compton}/bin/compton --dbus "$@"
      '';
      backend = "glx";
      vSync = "false";
      fade = true;
      fadeDelta = 4;
      extraOptions = ''
        # https://github.com/jEsuSdA/the-perfect-desktop/blob/master/compton/compton.conf
        unredir-if-possible = true;
        glx-no-stencil = true;
        glx-copy-from-front = false;
        #glx-use-copysubbuffermesa = true; # deprecated/removed
        glx-no-rebind-pixmap = true;
        #glx-swap-method = "undefined"; # deprecated
        #paint-on-overlay = true; # deprecated; always enabled
        sw-opti = false;
        detect-transient = true;
        detect-client-leader = true;
        mark-wmwin-focused = true;
        mark-ovredir-focused = true;
      '';
    };
  });
}
