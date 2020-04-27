{ lib, config, pkgs, ... }:

with lib;
let
  kernelCfg = config.my.kernel;
  overlayType = mkOptionType {
    name = "kernelPackages-overlay";
    check = isFunction;
    merge = mergeOneOption;
  };
in {
  options = {
    my.kernel = {
      kernel = mkOption {
        type = types.package;
        default = pkgs.linux;
      };
      pkgOverlays = mkOption {
        type = types.listOf overlayType;
        default = [];
      };
    };
  };

  config = {
    # Set kernel version
    boot.kernelPackages = let
      linuxPackages_base = pkgs.linuxPackagesFor kernelCfg.kernel;

      createPkgs =
        foldl composeExtensions (final: super: {}) kernelCfg.pkgOverlays;

      linuxPackages =
        linuxPackages_base.extend createPkgs;
    in linuxPackages;

    # Linux console settings
    console.font = "Lat2-Terminus16";
    console.keyMap = "us";

    # Locale settings
    i18n.defaultLocale = "en_US.UTF-8";

    # Clean /tmp on boot
    boot.cleanTmpDir = true;

    # Mount /tmp as tmpfs (in memory)
    boot.tmpOnTmpfs = true;
  };
}
