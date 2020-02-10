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
    asciinema
    direnv
    xclip xorg.xwininfo
    imagemagick

    # CLI programs
    taskwarrior

    # GUI programs
    chromium
    discord
    hexchat
    pavucontrol
    shutter
    vlc
    vscode
    qbittorrent
    obs-studio

    # Games
    steam
    multimc
  ];

  # Set GTK and Qt theme
  gtk = {
    enable = true;
    theme.package = pkgs.arc-theme;
    theme.name = "Arc-Dark";
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
      browser = [ "chromium.desktop" "firefox.desktop" ];
      torrent = [ "qbittorrent.desktop" ];
    in
      {
        "text/html" = browser;
        "x-scheme-handler/http" = browser;
        "x-scheme-handler/https" = browser;
        "x-scheme-handler/about" = browser;
        "x-scheme-handler/unknown" = browser;
        "application/x-bittorrent" = torrent;
        "x-scheme-handler/magnet" = torrent;
      };

  # Set default terminal
  home.sessionVariables.TERMINAL = "kitty";

  # Map caps to hyper
  home.keyboard.options = [ "caps:hyper" ];
  #home.file.".Xmodmap".text = ''
  #  clear lock
  #  clear mod4
  #  keycode 66 = Hyper_L
  #  keycode 133 = Super_L
  #'';

  # X Session
  xsession.enable = true;
  xsession.initExtra = ''
    # Disable OpenGL 'Sync to VBlank'
    nvidia-settings -a 'SyncToVBlank=0'

    # Disable OpenGL 'Allow Flipping'
    nvidia-settings -a 'AllowFlipping=0'

    # Set keyboard layout
    setxkbmap "ca(multi)" &

    # Set keyboard repeat delay/rate
    xset r rate 200 30 &
  '';
  xsession.windowManager.command = ''
    bspwm -c "$HOME/.bspwmrc"
  '';

  # Disable OpenGL 'Sync to VBlank'
  home.sessionVariables.__GL_SYNC_TO_VBLANK = 0;

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
