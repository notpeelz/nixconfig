{ stateVersion, channelSources ? {} }@args:
{ lib, config, pkgs, ... }:

with builtins;
let
  # Creates a list of overlays from the files in a directory
  makeOverlays = overlayRoot:
    let
      overlays = map (name: import (overlayRoot + "/${name}"))
        (attrNames (readDir overlayRoot));
    in overlays;

  channelSources = args.channelSources // {
    nixos-unstable = builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs-channels/archive/nixos-unstable.tar.gz";
    };
  };

  pkgs-unstable = import channelSources.nixos-unstable {
    inherit (config.nixpkgs) config;
    overlays = makeOverlays ./overlays-unstable;
  };
in {
  imports = [
    ./profiles/core.nix
    ./profiles/graphical.nix
    ./profiles/gaming.nix
    ./profiles/social.nix
    ./profiles/dev.nix
  ];

  # Allow non-free software.
  nixpkgs.config.allowUnfree = true;

  # Disable Home Manager manual
  manual.html.enable = false;
  manual.manpages.enable = false;

  # Overlays
  nixpkgs.overlays = lib.singleton (final: super: {
    # Make these available as pseudo-packages
    inherit pkgs-unstable;
  }) ++ makeOverlays ./overlays;

  # Packages
  home.packages = with pkgs; [
    # Misc programs
    wol
    stress
    rsync
    nethogs
    pv
    stow
    pandoc
    fortune
    imagemagick
  ];

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
