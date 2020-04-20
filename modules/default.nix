{ lib, config, pkgs, ... }:

{
  imports = [
    # TODO: import all files/folders automatically
    ./users.nix
    ./fix-zsh.nix
    ./hwdev.nix
  ];
}
