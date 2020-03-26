{ stateVersion, pkgs-unstable, theme, iconTheme, cursorTheme }:
{ config, pkgs, ... }:

let inherit (pkgs) fetchpatch;
in {
  # Allow non-free software.
  nixpkgs.config.allowUnfree = true;

  # Disable Home Manager manual
  manual.html.enable = false;
  manual.manpages.enable = false;

  # Overlays
  nixpkgs.overlays = [
    # Unstable programs
    (self: super: {
      inherit (pkgs-unstable)
        kitty
        bspwm
        sxhkd
        neovim
        nix-query-tree-viewer
        bless
        vulnix;
    })

    # zsh
    (self: super: {
      zsh = super.zsh.overrideAttrs ({ patches ? [], ... }: {
        patches = patches ++ builtins.map fetchpatch [
          # Reduces artifacts when resizing the terminal
          { url = "https://github.com/louistakepillz/zsh/commit/f016535cb6fd466207d16770d3dcedfafc1799e9.patch";
            sha256 = "06r6qpmsnwv0my44pim8vx311byf2h35y9xg3gpcchkxrhfngnws";
          }
          { url = "https://github.com/louistakepillz/zsh/commit/f5bf5a014675d3b8ff5c1da9f4de42363f0ba2aa.patch";
            sha256 = "0cfpnp2y4izzqlsylia2h8y2bgi8yarwjp59kmx6bcvd2vvv5bcx";
          }
        ];
      });
    })

    # kitty
    (self: super: {
      kitty = super.kitty.overrideAttrs ({ patches ? [], ... }: {
        patches = patches ++ builtins.map fetchpatch [
          # https://github.com/kovidgoyal/kitty/issues/2341
          # Fixes flipped mouse pointer on programs with mouse support
          { url = "https://github.com/kovidgoyal/kitty/commit/b235f411b06f9ccf09a6bbfdf245f52f64ee24e5.patch";
            sha256 = "13mn9rzyvxglsf8xjrdmsv1sj7lja73jb9hn0pvmacwgglpzi9vp";
          }
        ];
      });
    })

    # Neovim
    (self: super: {
      # Fix neovim's .desktop name showing up as "Neovim"
      neovim = super.neovim.overrideAttrs({ buildCommand, ... }: {
        buildCommand = builtins.replaceStrings
          [ "Name=WrappedNeovim" ] [ "Name=Neovim" ]
          buildCommand;
      });
    })

    # bspwm
    (self: super: {
      bspwm = super.bspwm.overrideAttrs ({ patches ? [], ... }: {
        patches = patches ++ builtins.map fetchpatch [
          # Fixes windows not getting resized properly when ignoring fullscreen events
          { url = "https://github.com/louistakepillz/bspwm/commit/538d6197532fcf8547548b68dac6b511de57232e.patch";
            sha256 = "072q2pg31vn52hb3b4q9v0m7cqbf7ibhy8y6rpmp3pcmd1ddmwzj";
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
    polybar
    nitrogen
    rofi

    # Terminal
    rxvt_unicode kitty
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

    # CLI programs
    asciinema
    taskwarrior
    ranger
    bc
    trash-cli
    (callPackage ../pkgs/rmtrash {})
    (neovim.override {
      viAlias = true;
      vimAlias = true;
    })

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
    gnome3.nautilus
    gnome3.gnome-system-monitor
    gnome3.file-roller

    # Chat programs
    hexchat
    discord
    (callPackage ../pkgs/betterdiscordctl {})

    # Games
    lutris
    # Fixes missing "Show game info" option; NixOS/nixpkgs#80184
    (steam.override (self: { extraLibraries = pkgs: [ lsof ]; }))
    multimc
  ];

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
