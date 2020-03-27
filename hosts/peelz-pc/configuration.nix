# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, ... }:

let
  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  stateVersion = "19.09";

  # Load secrets
  secrets = import ../../data/load-secrets.nix;

  # This allows refering to packages from the unstable channel.
  pkgs-unstable = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs-channels/archive/nixos-unstable.tar.gz";
  }) {
    inherit (config.nixpkgs) config;
  };

  # Declare download path for home-manager to avoid the need to have it as a channel.
  home-manager = builtins.fetchTarball {
    url = "https://github.com/rycee/home-manager/archive/release-${stateVersion}.tar.gz";
  };

  # Theme
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
in {
  imports = [
    ./hardware-configuration.nix
    ./persistence.nix
    ../../modules
    "${home-manager}/nixos"
  ];
  system.stateVersion = stateVersion;

  # Allow non-free software.
  nixpkgs.config.allowUnfree = true;

  # Hardware settings
  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  # Enable direct rendering for 32-bit applications (steam, wine, etc.)
  hardware.opengl.driSupport32Bit = true;

  # Use the systemd-boot EFI boot loader.
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

    linuxPackages = linuxPackages_base.extend (lib.const (super: {
      # NixOS 19.09: v4l2loopback 0.12.0 doesn't compile for Linux 5.x
      v4l2loopback = super.v4l2loopback.overrideAttrs (oldAttrs: rec {
        version = "0.12.3";
        name = "v4l2loopback-${version}-${super.kernel.version}";
        src = pkgs.fetchFromGitHub {
          owner = "umlaeute";
          repo = "v4l2loopback";
          rev = "v${version}";
          sha256 = "01wahmrh4iw27cfmypik6frapq14vn7m9shmj5g7cr1apz2523aq";
        };
      });

      # NixOS 19.09: use the r8125 kmod package from unstable
      r8125 = (pkgs-unstable.linuxPackagesFor kernel).r8125;
    }));
  in linuxPackages;

  # Kernel modules
  boot.extraModulePackages = with config.boot.kernelPackages; [
    v4l2loopback
    r8125
  ];
  boot.kernelModules = [ "r8125" ];

  # Clean /tmp on boot
  boot.cleanTmpDir = true;

  # Setup volume mount points
  fileSystems."/mnt/echo" = {
    device = "/dev/disk/by-uuid/56362696362676E1";
    fsType = "ntfs-3g";
  };
  fileSystems."/mnt/charlie" = {
    device = "/dev/disk/by-uuid/6EC886EBC886B0BF";
    fsType = "ntfs-3g";
  };
  fileSystems."/mnt/delta" = {
    device = "/dev/disk/by-uuid/BC4080AD40807046";
    fsType = "ntfs-3g";
  };
  fileSystems."/mnt/hotel" = {
    device = "/dev/disk/by-uuid/06804D92804D895F";
    fsType = "ntfs-3g";
  };
  fileSystems."/mnt/steam" = {
    device = "/dev/disk/by-uuid/1e20e85c-b692-411f-aab5-66c19ecb2bf5";
    fsType = "ext4";
  };
  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-uuid/9df014e5-955d-4e3a-92b1-7750a4cd3ebc";
    fsType = "ext4";
  };

  # Enable kvm
  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.qemuPackage = pkgs.qemu_kvm;

  # Enable dconf (required for virt-manager)
  programs.dconf.enable = true;

  # Enable docker
  virtualisation.docker.enable = true;

  # Set hostname
  networking.hostName = "peelz-pc";

  # Enable DHCP
  networking.useDHCP = false;
  networking.interfaces.enp5s0.useDHCP = true;
  networking.interfaces.enp4s0.useDHCP = true;

  # networking.wireless.enable = true;

  # Select internationalisation properties.
  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";
  };

  # Set your time zone.
  time.timeZone = "America/Montreal";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # System
    efibootmgr

    # Virtualization
    OVMF

    # Nix utils
    nix-index

    # General
    htop nvtop progress pstree killall
    curl wget
    neofetch
    git stow jq
    binutils file tree
    zip unzip p7zip unrar

    # Editor
    (neovim.override {
      viAlias = true;
      vimAlias = true;
    })

    # Text-based web browser
    w3m
  ];

  # Disable x11-ssh-askpass
  # https://github.com/NixOS/nixpkgs/issues/24311#issuecomment-528652343
  programs.ssh.askPassword = "";

  # Set bash as default shell
  users.defaultUserShell = pkgs.bash;

  # Enable zsh
  programs.zsh.enable = true;

  # Set neovim as default editor
  environment.sessionVariables.EDITOR = "nvim";

  # Enable sudo
  security.sudo.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [
    # Steam Remote Play
    27036 27037
  ];
  networking.firewall.allowedUDPPorts = [
    # Steam Remote Play
    27031 27036
  ];

  # Enable firewall.
  networking.firewall.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    # https://nixos.wiki/wiki/PulseAudio
    configFile = pkgs.runCommand "default.pa" {} ''
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
      realtime-scheduling = "yes";
      realtime-priority = 9;
      rlimit-rtprio = 9;
      default-fragment-size-msec = 5;
    };
  };

  # Fix PS3 controller not getting picked up
  services.udev.extraRules = ''
    KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0268", MODE="0660", TAG+="uaccess", GROUP="input"
  '';

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    layout = "ca(multi)";
    xkbOptions = "caps:hyper";
    videoDrivers = [ "nvidia" ];

    screenSection = lib.concatMapStrings (x: x + "\n") [
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
        inherit theme iconTheme cursorTheme;
      };
    };

    displayManager.setupCommands = let
      numlockx = "${pkgs.numlockx}/bin/numlockx";
      xset = "${pkgs.xorg.xset}/bin/xset";
    in ''
      # Enable numlock
      ${numlockx} on

      # Set keyboard repeat delay/rate
      ${xset} r rate 300 50

      # Turn off monitors after 5 minutes of inactivity
      ${xset} s 300 300 -dpms
    '';

    # Enable libinput
    libinput.enable = true;

    # Disable mouse acceleration
    # Enable autoscrolling (middle mouse click)
    config = ''
      Section "InputClass"
        Identifier "libinputConfiguration"
        Driver "libinput"
        MatchIsPointer "on"
        Option "AccelProfile" "flat"
        Option "ScrollMethod" "button"
        Option "ScrollButton" "2"
      EndSection
    '';

    desktopManager.default = "xsession";
    desktopManager.xterm.enable = false;
    desktopManager.gnome3.enable = false;
    desktopManager.session = [
      {
        manager = "desktop";
        name = "xsession";
        start = ''
          exec "$HOME/.xsession"
        '';
      }
    ];
  };

  # Enable gnome dbus (required for enabling themes)
  services.dbus.packages = with pkgs; [ gnome3.dconf ];

  # Fix Nautilus not being able to access GVFS paths
  # https://github.com/mate-desktop/caja/issues/1161#issuecomment-468299230
  services.gvfs.enable = true;
  environment.variables.GIO_EXTRA_MODULES = [
    "${pkgs.gnome3.gvfs}/lib/gio/modules"
  ];

  # Users
  users.mutableUsers = false;
  users.users.peelz = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "docker" "libvirtd" ];
    shell = pkgs.bash;
    initialHashedPassword = secrets.hashedPasswords.peelz;
  };
  users.users.root = {
    initialHashedPassword = secrets.hashedPasswords.root;
  };

  # Nix store settings
  nix.optimise.automatic = true;
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 8d";

  home-manager.users.peelz = (import ../../home-peelz/home.nix) {
    inherit pkgs-unstable stateVersion theme iconTheme cursorTheme;
  };
}
