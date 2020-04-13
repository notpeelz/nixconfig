{ lib, config, pkgs, ... }:

let
  # Essential packages
  essentials = import ../../../common/essentials.nix pkgs;

  # Replace interactive bash shells with zsh
  bashrc = pkgs.writeText "bashrc" ''
    [[ "$-" == *i* && -z "$IN_NIX_SHELL" ]] && exec "${pkgs.zsh}/bin/zsh"
  '';
in {
  home.packages = essentials ++ (with pkgs.pkgs-unstable; [
    (neovim.override {
      viAlias = true;
      vimAlias = true;
    })
  ]) ++ (with pkgs; [
    # Shell
    zsh

    # General utils
    tmux screen
    neofetch
    moreutils psutils
    nvtop progress
    ag
    stow
    git-crypt

    # CLI programs
    asciinema
    taskwarrior
    ranger
    bc
    trash-cli
    rmtrash

    # Nix utils
    nix-index
    nix-du
    nix-universal-prefetch
    nixos-eval-config
    haskellPackages.niv # NixOS 19.09: renamed to pkgs.niv on unstable
    nixfmt
    nixpkgs-review
    vulnix
    nix-query-tree-viewer
  ]);

  programs.fzf.enable = true;

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

  # Replace bash with zsh
  home.file.".bashrc".source = bashrc;
  home.file.".profile".source = bashrc;

  # Change zsh dotfile directory
  pam.sessionVariables.ZDOTDIR = "${config.home.homeDirectory}/.zsh";
}