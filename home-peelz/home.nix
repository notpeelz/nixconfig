{ stateVersion, channels, theme, iconTheme, cursorTheme }:
{ lib, config, pkgs, ... }:

with builtins;
let
  makeOverlays = overlayRoot:
    let
      overlays = map (name: import (overlayRoot + "/${name}"))
        (attrNames (readDir overlayRoot));
    in overlays;

  pkgs-unstable = import channels.nixos-unstable {
    inherit (config.nixpkgs) config;
    overlays = makeOverlays ./overlays-unstable;
  };
in {
  # Allow non-free software.
  nixpkgs.config.allowUnfree = true;

  # Disable Home Manager manual
  manual.html.enable = false;
  manual.manpages.enable = false;

  # Overlays
  nixpkgs.overlays = lib.singleton (final: super: {
    # Inject pkgs-unstable as a pseudo-package for the backports overlay
    inherit pkgs-unstable;
  }) ++ makeOverlays ./overlays;

  # Packages
  home.packages = (with pkgs-unstable; [
    # Bleeding edge packages
    kitty
    bspwm
    sxhkd
    (neovim.override {
      viAlias = true;
      vimAlias = true;
    })
  ]) ++ (with pkgs; [
    # Desktop environment
    polybar
    nitrogen
    rofi

    # Terminal
    rxvt_unicode
    zsh
    tmux screen

    # General programs
    curl wget
    git stow jq
    hexdump xxd
    binutils file tree ag
    zip unzip p7zip unrar
    htop nvtop progress psutils killall

    # Nix utils
    nix-index
    nix-du
    nixfmt
    nixpkgs-review
    vulnix
    nix-query-tree-viewer

    # Misc programs
    wol
    stress
    rsync
    nethogs
    pv
    stow
    pandoc
    fortune
    direnv
    imagemagick
    xdg_utils
    playerctl
    xclip
    xorg.xmodmap
    xorg.xwininfo
    xdotool

    # CLI programs
    asciinema
    taskwarrior
    ranger
    bc
    trash-cli
    rmtrash

    # GUI programs
    chromium firefox
    pavucontrol
    gimp
    vlc
    vscode
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

    # Chat programs
    hexchat
    discord betterdiscordctl

    # Games
    lutris
    # Fixes missing "Show game info" option; NixOS/nixpkgs#80184
    (steam.override (self: { extraLibraries = pkgs: [ lsof ]; }))
    multimc

    # Fonts
    nerdfonts # FIXME: this package is MASSIVE
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
  ]);

  services.lorri.enable = true;
  programs.fzf.enable = true;

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
  xdg.mimeApps.defaultApplications = let
    file_browser = [ "ranger.desktop" ];
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

  # Replace bash with zsh
  home.file.".bashrc".text = ''
    # -*- mode: sh -*-
    [[ "$-" == *i* && -z "$IN_NIX_SHELL" ]] && exec "${pkgs.zsh}/bin/zsh"
  '';

  # Change zsh dotfile directory
  pam.sessionVariables.ZDOTDIR = "${config.home.homeDirectory}/.zsh";

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
