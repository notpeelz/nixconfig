# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  stateVersion = "19.09";

  # Load secrets
  secrets = import ../../data/load-secrets.nix;

  # Declare download path for home-manager to avoid the need to have it as a channel
  home-manager = builtins.fetchTarball {
    url = "https://github.com/rycee/home-manager/archive/release-${stateVersion}.tar.gz";
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
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Setup volume mount points
  fileSystems."/mnt/echo" = {
    device = "/dev/disk/by-uuid/56362696362676E1";
    fsType = "ntfs";
  };

  # Enable kvm
  virtualisation.libvirtd.enable = true;

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
    # X11
    numlockx
    # Data transfer
    curl wget
    # System
    efibootmgr htop killall
    # General
    git stow jq vim neofetch
    binutils file unzip
    # Editor
    vim
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

  # Set vim as default editor
  programs.vim.defaultEditor = true;

  # Enable sudo
  security.sudo.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];

  # Enable firewall.
  networking.firewall.enable = true;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    layout = "ca(multi)";
    videoDrivers = [ "nvidia" ];

    screenSection = ''
      Option "metamodes" "DP-4: 3440x1440_120 +2560+0, DP-2: 2560x1440_120 +0+0"
    '';

    displayManager.lightdm.enable = true;

    displayManager.sessionCommands = let
      mouseName = "SINOWEALTH Wired Gaming Mouse";
    in ''
      numlockx on &
      mouseId="$(xinput list "${mouseName}" --id-only 2>/dev/null|grep -oP '(?<=id=)\d+')"
      xinput --set-prop "$mouseId" 'Evdev Wheel Emulation' 1
      xinput --set-prop "$mouseId" 'Evdev Wheel Emulation Button' 2
      xinput --set-prop "$mouseId" 'Evdev Wheel Emulation Axes' 6 7 4 5
      xinput --set-prop "$mouseId" 'Evdev Wheel Emulation Inertia' 7
    '';

    desktopManager.default = "xsession";
    desktopManager.xterm.enable = false;
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

  home-manager.users.peelz = (import ../../home-peelz/home.nix) { inherit stateVersion; };
}
