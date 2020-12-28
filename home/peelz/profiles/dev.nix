{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.my.dev;
in {
  options.my.dev = {
    enable = mkEnableOption "Dev programs";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      direnv
      vscode
      gdb
      ghidra-bin
      mitmproxy
    ];

    services.lorri.enable = true;
  };
}
