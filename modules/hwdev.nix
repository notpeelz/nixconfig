{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.my.hwdev;
in {
  options.my.hwdev = {
    enable = mkEnableOption "Hardware development";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; ([
      rtl-sdr
      geda
    ] ++ (optionals config.services.xserver.enable [
      gqrx
    ]));

    # Prevents the RTL2832U from loading the DVB-T kernel module
    boot.blacklistedKernelModules = [ "dvb_usb_rtl28xxu" ];

    # Udev rules
    services.udev.packages = with pkgs; [
      rtl-sdr
    ];

    # Arduino
    users.groups = {
      arduino = {};
    };
    services.udev.extraRules = ''
      SUBSYSTEM=="tty", ATTRS{manufacturer}=="Arduino*", SYMLINK+="arduino%n", MODE="0770", GROUP="arduino"
    '';
  };
}
