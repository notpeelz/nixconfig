{ stateVersion, channelSources ? { } }:
{ lib, config, pkgs, ... }:

with builtins;
with lib;
let
  # Creates a list of overlays from the files in a directory
  makeOverlays = overlayRoot:
    let
      overlays = map (name: import (overlayRoot + "/${name}"))
        (attrNames (readDir overlayRoot));
    in overlays;

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
