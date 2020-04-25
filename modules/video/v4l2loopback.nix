{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.my.video.v4l2loopback;
in {
  options.my.video.v4l2loopback = {
    enable = mkEnableOption "Virtual webcam";
  };

  config = mkIf cfg.enable {
    # 20.03: v4l2loopback 0.12.5 is required for kernel 5.5
    # https://github.com/umlaeute/v4l2loopback/issues/257
    my.kernel.pkgOverlays = [
      (final: super: {
        v4l2loopback = super.v4l2loopback.overrideAttrs (const rec {
          name = "v4l2loopback-${version}-${super.kernel.version}";
          version = "0.12.5";
          src = pkgs.fetchFromGitHub {
            owner = "umlaeute";
            repo = "v4l2loopback";
            rev = "v${version}";
            sha256 = "1qi4l6yam8nrlmc3zwkrz9vph0xsj1cgmkqci4652mbpbzigg7vn";
          };
        });
      })
    ];

    # Extra kernel modules
    boot.extraModulePackages = with config.boot.kernelPackages; [
      v4l2loopback
    ];

    # Register a v4l2loopback device at boot
    boot.kernelModules = [
      "v4l2loopback"
    ];
    boot.extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1 video_nr=9 card_label=v4l2sink
    '';
  };
}
