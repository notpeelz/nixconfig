{ lib, stdenv }:

with lib;
stdenv.mkDerivation {
  pname = "rtl8761b-firmware";
  version = "20200610";

  src = builtins.fetchTarball {
    url = "https://mpow.s3-us-west-1.amazonaws.com/mpow_MPBH456AB_driver+for+Linux.tgz";
    sha256 = "0mq2jq0mhmh2mjxhbr74hgv63ji77n2vn4phfpg55x7j9kixjs1a";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p "$out/lib/firmware/rtl_bt"
    cp "$src/rtkbt-firmware/lib/firmware/rtl8761bu_fw" "$out/lib/firmware/rtl_bt/rtl8761b_fw.bin"
    cp "$src/rtkbt-firmware/lib/firmware/rtl8761bu_config" "$out/lib/firmware/rtl_bt/rtl8761b_config.bin"
  '';

  meta = with lib; {
    description = "Firmware for Realtek 8761b";
    license = licenses.unfreeRedistributableFirmware;
    platforms = with platforms; linux;
  };
}
