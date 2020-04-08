{ lib, config, pkgs, ... }:

with lib;
let
  enableZsh = filter
    (user: any ({ pname ? null, ... }: pname == "zsh") user.home.packages)
    (attrValues config.home-manager.users) != [];
in {
  config = mkIf enableZsh {
    environment.systemPackages = with pkgs; [ nix-zsh-completions ];
    environment.pathsToLink = singleton "/share/zsh";
  };
}
