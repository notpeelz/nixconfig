{ lib, config, pkgs, ... }:

with lib;
{
  # Linux console settings
  console.font = "Lat2-Terminus16";
  console.keyMap = "us";

  # Locale settings
  i18n.defaultLocale = "en_US.UTF-8";

  # Clean /tmp on boot
  boot.cleanTmpDir = true;

  # Mount /tmp as tmpfs (in memory)
  boot.tmpOnTmpfs = true;

  # Disable x11-ssh-askpass
  # https://github.com/NixOS/nixpkgs/issues/24311#issuecomment-528652343
  programs.ssh.askPassword = "";
}
