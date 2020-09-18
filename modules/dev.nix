{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.my.dev;
in {
  options.my.dev = {
    enable = mkEnableOption "Development";
  };

  config = mkIf cfg.enable {
    # Enable usb capture for wireshark and usbtop
    boot.kernelModules = [ "usbmon" ];
    environment.systemPackages = with pkgs; [ usbtop ];

    programs.wireshark.enable = true;
    programs.wireshark.package = mkIf config.my.graphical.enable pkgs.wireshark-qt;

    # Udev rules
    services.udev.packages = with pkgs; [
      # https://superuser.com/a/861052/1129836
      (writeTextDir "etc/udev/rules.d/99-usbmon.rules" ''
        SUBSYSTEM=="usbmon", GROUP="usbmon", MODE="660"
      '')
    ];

    # Udev group
    users.groups = {
      usbmon = {};
    };
  };
}
