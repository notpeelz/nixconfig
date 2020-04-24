# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, ... }:

with lib;
let
  makeOverlays = overlayRoot:
    let
      inherit (builtins) readDir;
      overlays = map (name: import (overlayRoot + "/${name}"))
        (attrNames (readDir overlayRoot));
    in overlays;

  # Load secrets
  secrets = import ../../data/load-secrets.nix;

  # This allows refering to packages from other channels.
  channelSources = {
    nixos-unstable = builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs-channels/archive/nixos-unstable.tar.gz";
    };

    home-manager = builtins.fetchTarball {
      url = "https://github.com/rycee/home-manager/archive/release-20.03.tar.gz";
    };
  };

  pkgs-unstable = import channelSources.nixos-unstable {
    inherit (config.nixpkgs) config;
  };
in {
  imports = [
    ../../modules
    ./hardware-configuration.nix
    ./persistence.nix
    "${channelSources.home-manager}/nixos"
  ];

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "20.03";

  # Allow non-free software
  nixpkgs.config.allowUnfree = true;

  # Overlays
  nixpkgs.overlays = singleton (final: super: {
    # Make these available as pseudo-packages
    inherit channelSources pkgs-unstable;
  }) ++ makeOverlays ./overlays;

  # Use GRUB bootloader
  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      devices = [ "nodev" ];
      efiSupport = true;
      useOSProber = true;
    };
  };

  # Set kernel version
  boot.kernelPackages = let
    kernel = pkgs.linux_latest;
    # kernel = let
    #   base = pkgs-unstable.linux_latest;
    # in pkgs.linuxManualConfig {
    #   inherit (pkgs) stdenv;
    #   inherit (base) version src;
    #   allowImportFromDerivation = false;
    #   configfile = pkgs.linuxConfig {
    #     makeTarget = "defconfig";
    #     inherit (base) src;
    #   };
    # };

    linuxPackages_base = pkgs.linuxPackagesFor kernel;

    linuxPackages = linuxPackages_base.extend (const (super: {
      # 20.03: v4l2loopback 0.12.5 is required for kernel 5.5
      # https://github.com/umlaeute/v4l2loopback/issues/257
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

      # NixOS 19.09: use the r8125 kmod package from unstable
      r8125 = (pkgs-unstable.linuxPackagesFor kernel).r8125;
    }));
  in linuxPackages;

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

  # Enable kvm
  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.qemuPackage = pkgs.qemu_kvm;

  # Enable docker
  virtualisation.docker.enable = true;

  # Set hostname
  networking.hostName = "peelz-pc";

  # Enable DHCP
  networking.interfaces.enp5s0.useDHCP = true;
  networking.interfaces.enp4s0.useDHCP = true;

  # Time zone
  time.timeZone = "America/Montreal";

  # System packages
  environment.systemPackages = with pkgs; [
    # System
    efibootmgr

    # Virtualization
    OVMF

    # Nix utils
    nix-index

    # General
    nvtop progress

    # Editor
    (neovim.override {
      viAlias = true;
      vimAlias = true;
    })

    # Text-based web browser
    w3m
  ];

  # Set neovim as default editor
  environment.sessionVariables.EDITOR = "nvim";

  # Open ports in the firewall
  networking.firewall.allowedTCPPorts = [
    # Steam Remote Play
    27036 27037
  ];
  networking.firewall.allowedUDPPorts = [
    # Steam Remote Play
    27031 27036
  ];

  # Enable CUPS to print documents
  services.printing.enable = true;

  # Enable sound
  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    # https://nixos.wiki/wiki/PulseAudio
    configFile = pkgs.runCommand "default.pa" { } ''
      sed '
        s/module-udev-detect$/module-udev-detect tsched=0/
        s/^load-module module-suspend-on-idle$//
      ' \
      ${pkgs.pulseaudio}/etc/pulse/default.pa > $out
    '';
    daemon.config = {
      flat-volumes = "no";
      # https://wiki.archlinux.org/index.php/Gaming#Using_higher_quality_remixing_for_better_sound
      # https://web.archive.org/web/20200228004644/https://forums.linuxmint.com/viewtopic.php?f=42&t=44862
      high-priority = "yes";
      resample-method = "speex-float-10";
      nice-level = -11;
      # realtime scheduling occasionally causes choppy audio
      #realtime-scheduling = "yes";
      #realtime-priority = 9;
      #rlimit-rtprio = 9;
      default-fragments = 2;
      default-fragment-size-msec = 4;
    };
  };

  # Screen configuration
  services.xserver = {
    screenSection = concatStringsSep "\n" [
      # Set primary display
      ''Option "nvidiaXineramaInfoOrder" "DP-4"''
      # Set display configuration
      ''Option "metamodes" "DP-4: 3440x1440_120 +1440+560 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}, DP-2: 2560x1440_120 +0+0 {rotation=right, ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}"''
      # Fix automatic DPI scaling when a display is rotated
      ''Option "DPI" "108 x 107"''
    ];

    displayManager.lightdm = {
      enable = true;
      background = builtins.fetchurl {
        url = "https://i.imgur.com/QLntV2f.jpg";
        sha256 = "1aznl543qicsa3y37wb1zgxzlrkngf5x2yrmz75w5a6hwbpvvd34";
      };
      greeters.gtk = {
        enable = true;
        indicators = [ "~clock" "~spacer" "~a11y" "~session" "~power"];
        theme = {
          package = pkgs.arc-theme;
          name = "Arc-Dark";
        };
        iconTheme = {
          package = pkgs.arc-icon-theme;
          name = "Arc";
        };
        cursorTheme = {
          package = pkgs.capitaine-cursors;
          name = "capitaine-cursors";
          size = 40;
        };
      };
    };
  };

  # Enable direct rendering for 32-bit applications (steam, wine, etc.)
  hardware.opengl.driSupport32Bit = true;

  # Users
  users.mutableUsers = false;
  users.users.root = {
    initialHashedPassword = secrets.hashedPasswords.root;
  };
  my.users.users.peelz = {
    config = {
      isNormalUser = true;
      uid = 1000;
      extraGroups = [
        "wheel"
        "docker"
        "libvirtd"
        "wireshark"
        "arduino"
      ];
      shell = pkgs.bash;
      initialHashedPassword = secrets.hashedPasswords.peelz;
    };

    overrides = {
      my.graphical = {
        wm.bspwm.monitors = {
          primary = "DP-4";
          secondary = "DP-2";
        };
        nvidia.enable = true;
      };

      my.gaming = {
        enable = true;
        ultrawide = true;
      };

      my.social.enable = true;

      my.dev.enable = true;
    } // (with config.services.xserver.displayManager.lightdm.greeters.gtk; {
      # Copy theme settings from lightdm
      gtk.theme = theme;
      gtk.iconTheme = iconTheme;
      xsession.pointerCursor = cursorTheme;
    });
  };

  # Custom modules
  my.graphical.enable = true;
  my.graphical.nvidia.enable = true;
  my.hwdev.enable = true;
  my.dev.enable = true;

  # Nix store settings
  nix.optimise.automatic = true;
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 8d";
}
