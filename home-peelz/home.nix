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

    # General programs
    htop
    rxvt_unicode kitty
    tmux
    neovim

    # Misc programs
    stow
    git curl wget jq
    unzip
    fortune
    xclip

    # GUI programs
    chromium
    discord
    pavucontrol
    shutter
    obs-studio
  ];

  services.redshift = {
    enable = true;
    provider = "manual";
    latitude = "45.50";
    longitude = "-73.57";
    temperature.day = 6500;
    temperature.night = 3200;
  };

  # Set default programs
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications =
    let
      browser = [ "chromium.desktop" "firefox.desktop" ];
    in
      {
        "text/html" = browser;
        "x-scheme-handler/http" = browser;
        "x-scheme-handler/https" = browser;
        "x-scheme-handler/about" = browser;
        "x-scheme-handler/unknown" = browser;
      };

  # X Session
  xsession.enable = true;
  xsession.initExtra = ''
    setxkbmap "ca(multi)" &
    xset r rate 200 30 &
  '';
  xsession.windowManager.command = ''
    bspwm -c "$HOME/.bspwmrc"
  '';

  # Session variables
  # home.sessionVariables.MY_VAR = 1;

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
