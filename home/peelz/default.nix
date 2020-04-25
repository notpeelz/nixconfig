{ stateVersion, channelSources ? { } }:
{ lib, config, pkgs, ... }:

with builtins;
with lib;
let channelSources' = channelSources;
in let
  # Creates a list of overlays from the files in a directory
  makeOverlays = overlayRoot:
    let
      overlays = map (name: import (overlayRoot + "/${name}"))
        (attrNames (readDir overlayRoot));
    in overlays;

  # Use sources from the host if possible, otherwise fall back to the latest
  # upstream rev
  channelSources = {
    nixos-unstable = fetchTarball {
      url = "https://github.com/NixOS/nixpkgs-channels/archive/nixos-unstable.tar.gz";
    };
  } // channelSources';

  pkgs-unstable = import channelSources.nixos-unstable {
    inherit (config.nixpkgs) config;
    overlays = makeOverlays ./overlays-unstable;
  };
in {
  imports = let
    moduleRoot = ./profiles;
    modules = map (name: import (moduleRoot + "/${name}"))
      (attrNames (readDir moduleRoot));
  in modules;

  # Allow non-free software.
  nixpkgs.config.allowUnfree = true;

  # Disable Home Manager manual
  manual.html.enable = false;
  manual.manpages.enable = false;

  # Overlays
  nixpkgs.overlays = singleton (final: super: {
    # Make these available as pseudo-packages
    inherit pkgs-unstable;
  }) ++ makeOverlays ./overlays;

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
