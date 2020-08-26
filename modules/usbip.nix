{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.my.usbip;
in {
  options.my.usbip = {
    enable = mkEnableOption "USB/IP Client";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with config.boot.kernelPackages; [
      usbip
    ];

    # Kernel modules
    boot.kernelModules = [ "usbip_core" "usbip_hcd" "vhci_hcd" ];
    boot.extraModulePackages = with config.boot.kernelPackages; [
      usbip
    ];

    # Fix missing hwdata
    my.kernel.pkgOverlays = [
      (final: super: {
        usbip = super.usbip.overrideAttrs ({ configureFlagsArray ? [], ... }: {
          configureFlagsArray = configureFlagsArray ++ [
            "--with-usbids-dir=${pkgs.hwdata}/share/hwdata/"
          ];
        });
      })
    ];
  };
}
