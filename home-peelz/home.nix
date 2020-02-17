{ stateVersion }:
{ config, pkgs, ... }:

{
  # Allow non-free software.
  nixpkgs.config.allowUnfree = true;

  # Disable Home Manager manual
  manual.html.enable = false;
  manual.manpages.enable = false;

  # Packages
  home.packages = with pkgs; [
    # Desktop environment
    bspwm
    sxhkd
    nitrogen
    rofi

    # General programs
    rxvt_unicode kitty
    tmux
    neovim

    # Misc programs
    stow
    git curl wget jq
    unzip
    fortune
    direnv
    imagemagick
    xclip
    xorg.xmodmap
    xorg.xwininfo

    # CLI programs
    asciinema
    taskwarrior
    ranger

    # GUI programs
    chromium
    discord
    hexchat
    pavucontrol
    gimp
    shutter
    vlc
    vscode
    qbittorrent
    obs-studio
    spectacle

    # Games
    lutris
    # Fixes missing "Show game info" option; NixOS/nixpkgs#80184
    (steam.override (self: { extraLibraries = pkgs: [ lsof ]; }))
    multimc
  ];

  services.compton = {
    enable = true;
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

  # Set GTK and Qt theme
  gtk = {
    enable = true;
    theme.package = pkgs.arc-theme;
    theme.name = "Arc-Dark";
    iconTheme.package = pkgs.arc-icon-theme;
    iconTheme.name = "Arc";
  };
  qt = {
    enable = true;
    platformTheme = "gtk";
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

  # Set well-known directories
  xdg.userDirs = {
    enable = true;
    desktop = "$HOME/desktop";
    documents = "$HOME/documents";
    download = "$HOME/downloads";
    music = "$HOME/music";
    pictures = "$HOME/pictures";
    videos = "$HOME/videos";
  };

  # Set default programs
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications =
    let
      file_browser = [ "ranger.desktop" ];
      web_browser = [ "chromium.desktop" "firefox.desktop" ];
      torrent = [ "qbittorrent.desktop" ];
    in
      {
        "inode/directory" = file_browser;
        "text/html" = web_browser;
        "x-scheme-handler/http" = web_browser;
        "x-scheme-handler/https" = web_browser;
        "x-scheme-handler/about" = web_browser;
        "x-scheme-handler/unknown" = web_browser;
        "application/x-bittorrent" = torrent;
        "x-scheme-handler/magnet" = torrent;
      };

  # Set default terminal
  home.sessionVariables.TERMINAL = "kitty";

  # Map caps to hyper
  home.keyboard.options = [ "caps:hyper" ];

  # X Session
  xsession.enable = true;
  xsession.initExtra = ''
    # Disable OpenGL 'Sync to VBlank'
    nvidia-settings -a 'SyncToVBlank=0' &

    # Disable OpenGL 'Allow Flipping'
    nvidia-settings -a 'AllowFlipping=0' &

    # Set keyboard layout
    setxkbmap "ca(multi)" &

    # Set keyboard repeat delay/rate
    xset r rate 200 30 &

    # Fix Overwatch (Lutris) detecting RCtrl instead of LCtrl
    xmodmap -e "keycode 37 = Control_R NoSymbol Control_R" &

    # Restore wallpaper
    nitrogen --restore &
  '';
  xsession.windowManager.command = ''
    bspwm -c "$HOME/.bspwmrc"
  '';

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = stateVersion;
}
