{ lib, config, pkgs, ... }:

with lib;
{
  config = {
    hardware.firmware = [ (pkgs.callPackage ./rtl8761b-fw.nix {}) ];
    boot.kernelPatches = [
      { name = "RTL8761b firmware support";
        # https://patchwork.kernel.org/patch/11483367/
        patch = ./btrtl-rtl8761b.diff;
      }
    ];
  };
}
