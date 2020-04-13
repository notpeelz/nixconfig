{ lib, config, pkgs, ... }:

with lib;
let
  hmSrc = pkgs.channelSources.home-manager;
  cfg = config.my.graphical;
in {
  options.my.graphical = {
    enable = mkEnableOption "Graphical environment";
  };

  config = mkIf cfg.enable {
    # Packages
    home.packages = (with pkgs.pkgs-unstable; [
      # Bleeding edge packages
      kitty
      bspwm
      sxhkd
    ]) ++ (with pkgs; [
      # Desktop environment
      polybar
      nitrogen
      rofi
      playerctl
      xclip
      xdg_utils
      xorg.xmodmap
      xorg.xwininfo
      xdotool

      # Programs
      chromium firefox
      pavucontrol
      gimp
      vlc
      qbittorrent
      virtmanager
      obs-studio
      shutter spectacle peek
      screenkey
      wireshark
      qdirstat
      remmina
      bless

      # Gnome utilities
      gnome3.gnome-calendar
      gnome3.gnome-calculator
      gnome3.nautilus
      gnome3.gnome-system-monitor
      gnome3.file-roller

      # Fonts
      nerdfonts # FIXME: this package is MASSIVE
    ]);

    # Enable fontconfig (required for generating ~/.cache/fontconfig)
    # 19.09: mkForce avoids an option conflict; https://github.com/rycee/home-manager/issues/1118
    fonts.fontconfig.enable = mkForce true;

    # Set GTK and Qt theme
    gtk = {
      enable = true;
      theme = mkDefault {
        package = pkgs.arc-theme;
        name = "Arc-Dark";
      };
      iconTheme = mkDefault {
        package = pkgs.arc-icon-theme;
        name = "Arc";
      };
    };
    qt = {
      enable = true;
      platformTheme = "gtk";
    };

    # Set cursor
    xsession.pointerCursor = mkDefault {
      package = pkgs.capitaine-cursors;
      name = "capitaine-cursors";
    };

    # Set default programs
    xdg.mimeApps.enable = true;
    xdg.mimeApps.defaultApplications = let
      file_browser = [ "org.gnome.Nautilus.desktop" ];
      web_browser = [ "chromium-browser.desktop" ];
      torrent = [ "qbittorrent.desktop" ];
    in {
      "inode/directory" = file_browser;
      "text/html" = web_browser;
      "x-scheme-handler/http" = web_browser;
      "x-scheme-handler/https" = web_browser;
      "x-scheme-handler/about" = web_browser;
      "x-scheme-handler/unknown" = web_browser;
      "application/x-bittorrent" = torrent;
      "x-scheme-handler/magnet" = torrent;
    };

    # Set default browser
    pam.sessionVariables.BROWSER = "chromium";
    pam.sessionVariables.BROWSER_INCOGNITO = "chromium --incognito";

    # Set default terminal
    pam.sessionVariables.TERMINAL = "kitty";

    # Map caps to hyper
    home.keyboard.options = [ "caps:hyper" ];

    # X Session
    xsession.enable = true;
    xsession.initExtra = ''
      # Disable OpenGL 'Sync to VBlank'
      nvidia-settings -a 'SyncToVBlank=0' &

      # Disable OpenGL 'Allow Flipping'
      nvidia-settings -a 'AllowFlipping=0' &

      # Restore wallpaper
      nitrogen --restore &
    '';

    # Set up window manager
    xsession.windowManager.command = let
      xidlehook = "${pkgs.xidlehook}/bin/xidlehook";
      dm-tool = "${pkgs.lightdm}/bin/dm-tool";
      bspwm = "${pkgs.bspwm}/bin/bspwm";
    in ''
      # Monitors turn off after 5 minutes;
      # session will be locked 20 seconds after that if not woken up
      ${xidlehook} \
        --not-when-fullscreen \
        --not-when-audio \
        --timer primary 320 '${dm-tool} lock' \'\' &
      xidlehook_PID="$!"

      # Start bspwm
      ${bspwm} -c "$HOME/.bspwmrc"

      kill "$xidlehook_PID"
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

    # Enable Redshift for night time
    services.redshift = {
      enable = true;
      provider = "manual";
      latitude = "45.50";
      longitude = "-73.57";
      temperature.day = 6500;
      temperature.night = 3200;
    };
  };
}
