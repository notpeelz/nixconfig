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
  pkgs-unstable = (import (builtins.fetchTarball {
    url = https://github.com/NixOS/nixpkgs-channels/archive/nixos-unstable.tar.gz;
  })) {
    config = config.nixpkgs.config;
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
  boot.kernelPackages = pkgs.linuxPackages_custom;

  # Kernel modules
  boot.extraModulePackages = with config.boot.kernelPackages; [
    v4l2loopback
  ];

  nixpkgs.overlays = [
    (self: super: rec {
      linuxPackages_latest = linuxPackages_custom;
      linuxPackages_custom = super.linuxPackages_latest.extend (kSelf: kSuper: {
        # NixOS 19.09: v4l2loopback 0.12.0 doesn't compile for Linux 5.x
        v4l2loopback = kSuper.v4l2loopback.overrideAttrs (oldAttrs: rec {
          version = "0.12.3";
          name = "v4l2loopback-${version}-${kSuper.kernel.version}";
          src = pkgs.fetchFromGitHub {
            owner = "umlaeute";
            repo = "v4l2loopback";
            rev = "v${version}";
            sha256 = "01wahmrh4iw27cfmypik6frapq14vn7m9shmj5g7cr1apz2523aq";
          };
        });
      });
    })
  ];


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

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp5s0.useDHCP = true;

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
    efibootmgr htop nvtop progress pstree killall

    # Nix utils
    nix-index

    # General
    curl wget
    git stow jq neofetch
    binutils file tree
    zip unzip p7zip unrar

    # Virtualization
    OVMF
    virtmanager

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

  # Patch zsh to support p10k redraws on SIGWINCH
  #nixpkgs.config.packageOverrides = pkgs: {
  #  zsh =
  #    let
  #      forcedVersion = "5.7.1";
  #    in pkgs.zsh.overrideAttrs (oldAttrs: rec {
  #      version = lib.traceIf
  #        (lib.versionOlder forcedVersion oldAttrs.version) "forcing outdated zsh version ${forcedVersion} -- patches have to be updated"
  #        forcedVersion;
  #      patches = builtins.map builtins.fetchurl [
  #        { url = "https://github.com/LouisTakePILLz/zsh/commit/f016535cb6fd466207d16770d3dcedfafc1799e9.patch";
  #          sha256 = "06r6qpmsnwv0my44pim8vx311byf2h35y9xg3gpcchkxrhfngnws";
  #        }
  #        { url = "https://github.com/LouisTakePILLz/zsh/commit/f5bf5a014675d3b8ff5c1da9f4de42363f0ba2aa.patch";
  #          sha256 = "0cfpnp2y4izzqlsylia2h8y2bgi8yarwjp59kmx6bcvd2vvv5bcx";
  #        }
  #      ];
  #    });
  #};

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
  # services.printing.enable = true;

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

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    layout = "ca(multi)";
    xkbOptions = "caps:hyper";
    videoDrivers = [ "nvidia" ];

    screenSection = ''
      Option "nvidiaXineramaInfoOrder" "DP-4"
      Option "metamodes" "DP-4: 3440x1440_120 +2560+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}, DP-2: 2560x1440_120 +0+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}"
    '';

    displayManager.lightdm = {
      enable = true;
      background = builtins.fetchurl {
        url = https://i.imgur.com/QLntV2f.jpg;
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

  # Users
  users.mutableUsers = false;
  users.users.peelz = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "docker" "libvirtd" ];
    shell = pkgs.zsh;
    initialHashedPassword = secrets.hashedPasswords.peelz;
  };
  users.users.root = {
    initialHashedPassword = secrets.hashedPasswords.root;
  };

  home-manager.users.peelz = (import ../../home-peelz/home.nix) {
    inherit pkgs-unstable stateVersion theme iconTheme cursorTheme;
  };
}
