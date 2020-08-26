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
    ] ++ (optionals config.services.xserver.enable [
      gqrx
    ]));

    # Prevents the RTL2832U from loading the DVB-T kernel module
    boot.blacklistedKernelModules = [ "dvb_usb_rtl28xxu" ];

    # Udev rules
    services.udev.packages = with pkgs; [
      rtl-sdr
      (writeTextDir "etc/udev/rules.d/49-micronucleus.rules" ''
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="16d0", ATTRS{idProduct}=="0753", MODE:="0770", GROUP="arduino"
        KERNEL=="ttyACM*", ATTRS{idVendor}=="16d0", ATTRS{idProduct}=="0753", MODE:="0770", ENV{ID_MM_DEVICE_IGNORE}="1", GROUP="arduino"
      '')
      (writeTextDir "etc/udev/rules.d/99-arduino.rules" ''
        SUBSYSTEM=="tty", ATTRS{manufacturer}=="Arduino*", SYMLINK+="arduino%n", MODE="0770", GROUP="arduino"
      '')
    ];

    # Arduino
    users.groups = {
      arduino = {};
    };
  };
}
