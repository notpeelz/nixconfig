{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.my.essentials;
  essential-pkgs = import ../common/essential-pkgs.nix pkgs;
in {
  options.my.essentials = {
    enable = mkEnableOption "System essentials" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    # Enable sudo
    security.sudo.enable = true;

    # Set bash as default shell
    users.defaultUserShell = pkgs.bash;

    # Enable firewall
    networking.firewall.enable = true;

    # Disable x11-ssh-askpass
    # https://github.com/NixOS/nixpkgs/issues/24311#issuecomment-528652343
    programs.ssh.askPassword = "";

    # System packages
    environment.systemPackages = essential-pkgs;
  };
}
