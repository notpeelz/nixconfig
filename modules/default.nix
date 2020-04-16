{ lib, config, pkgs, ... }:

{
  imports = [
    # TODO: import all files/folders automatically
    ./fix-zsh.nix
    ./hwdev.nix
  ];
}
