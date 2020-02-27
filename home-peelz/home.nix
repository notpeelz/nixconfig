{ stateVersion, pkgs-unstable, theme, iconTheme, cursorTheme }:
{ config, pkgs, ... }:

{
  # Allow non-free software.
  nixpkgs.config.allowUnfree = true;

  # Disable Home Manager manual
  manual.html.enable = false;
  manual.manpages.enable = false;

  # Overlays
  nixpkgs.overlays = [
    (self: super: {
      kitty = super.kitty.overrideAttrs (oldAttrs: {
        patches = oldAttrs.patches ++ builtins.map builtins.fetchurl [
          # https://github.com/kovidgoyal/kitty/issues/2341
          # Fixes flipped mouse pointer on programs with mouse support
          { url = https://github.com/kovidgoyal/kitty/commit/b235f411b06f9ccf09a6bbfdf245f52f64ee24e5.patch;
            sha256 = "13mn9rzyvxglsf8xjrdmsv1sj7lja73jb9hn0pvmacwgglpzi9vp";
          }
        ];
      });
    })
  ];

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
    hexdump xxd
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
    vlc
    vscode
    qbittorrent
    obs-studio
    shutter spectacle peek
    screenkey
    wireshark
    qdirstat
    pkgs-unstable.bless
    gnome3.gnome-system-monitor

    # Games
    lutris
    # Fixes missing "Show game info" option; NixOS/nixpkgs#80184
    (steam.override (self: { extraLibraries = pkgs: [ lsof ]; }))
    multimc
  ];

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

  # Set GTK and Qt theme
  gtk = {
    enable = true;
    inherit theme iconTheme;
  };
  qt = {
    enable = true;
    platformTheme = "gtk";
  };

  # Set cursor
  xsession.pointerCursor = cursorTheme;

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
      web_browser = [ "chromium-browser.desktop" ];
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
        #"image/png" = image;
        #"image/jpg" = image;
      };

  # Set default browser
  home.sessionVariables.BROWSER = "chromium";
  home.sessionVariables.BROWSER_INCOGNITO = "chromium --incognito";

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

    # Fix Overwatch (Lutris) detecting RCtrl instead of LCtrl
    # https://bugs.winehq.org/show_bug.cgi?id=45148
    # Fixed in wine >=5.0_rc1 (2019-12-10)
    xmodmap -e "keycode 37 = Control_R NoSymbol Control_R" &

    # Restore wallpaper
    nitrogen --restore &
  '';

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
