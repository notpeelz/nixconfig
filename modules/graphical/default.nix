{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.my.graphical;
in {
  imports = [
    ./nvidia.nix
  ];

  options.my.graphical = {
    enable = mkEnableOption "Graphical environment";
  };

  config = mkIf cfg.enable {
    # Enable dconf (required for virt-manager)
    programs.dconf.enable = true;

    # Enable gnome dbus (required for enabling themes)
    services.dbus.packages = with pkgs; [ gnome3.dconf ];

    # Fix Nautilus not being able to access GVFS paths
    # https://github.com/mate-desktop/caja/issues/1161#issuecomment-468299230
    services.gvfs.enable = true;
    environment.variables.GIO_EXTRA_MODULES = [
      "${pkgs.gnome3.gvfs}/lib/gio/modules"
    ];

    # Enable the X11 window system
    services.xserver = {
      enable = true;
      layout = "ca(multi)";
      xkbOptions = "caps:hyper";

      displayManager.defaultSession = "xsession";
      desktopManager.session = singleton {
        manager = "desktop";
        name = "xsession";
        start = ''
            exec "$HOME/.xsession"
        '';
      };

      # FIXME: add numlockx to systemd.user.services.setxkbmap.Service
      #        in profiles/graphical
      displayManager.setupCommands = ''
        # Enable numlock
        ${pkgs.numlockx}/bin/numlockx on

        # Set keyboard repeat delay/rate
        ${pkgs.xorg.xset}/bin/xset r rate 300 50

        # Turn off monitors after 5 minutes of inactivity
        ${pkgs.xorg.xset}/bin/xset s 300 300 -dpms
      '';

      libinput = {
        enable = true;
        # Disable mouse acceleration
        accelProfile = "flat";
        accelSpeed = "0";
        # Enable autoscrolling (middle mouse click)
        scrollMethod = "button";
        scrollButton = 2;
        # Prevents lmb+rmb from sending a middle-mouse click
        middleEmulation = false;
      };
    };
  };
}
