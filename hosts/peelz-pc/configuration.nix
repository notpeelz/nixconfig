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
  fileSystems."/mnt/charlie" = {
    device = "/dev/disk/by-uuid/6EC886EBC886B0BF";
    fsType = "ntfs";
  };
  fileSystems."/mnt/delta" = {
    device = "/dev/disk/by-uuid/BC4080AD40807046";
    fsType = "ntfs";
  };
  fileSystems."/mnt/hotel" = {
    device = "/dev/disk/by-uuid/06804D92804D895F";
    fsType = "ntfs";
  };
  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-uuid/1e20e85c-b692-411f-aab5-66c19ecb2bf5";
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
    # X11
    numlockx

    # System
    efibootmgr htop nvtop killall

    # Nix utils
    nix-index

    # General
    curl wget
    git stow jq neofetch
    binutils file unzip p7zip

    # Virtualization
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
  nixpkgs.config.packageOverrides = pkgs: {
    zsh =
      let
        forcedVersion = "5.7.1";
      in pkgs.zsh.overrideAttrs (oldAttrs: rec {
        version = lib.traceIf
          (lib.versionOlder forcedVersion oldAttrs.version) "forcing outdated zsh version ${forcedVersion} -- patches have to be updated"
          forcedVersion;
        patches = builtins.map builtins.fetchurl [
          { url = "https://github.com/LouisTakePILLz/zsh/commit/f016535cb6fd466207d16770d3dcedfafc1799e9.patch";
            sha256 = "06r6qpmsnwv0my44pim8vx311byf2h35y9xg3gpcchkxrhfngnws";
          }
          { url = "https://github.com/LouisTakePILLz/zsh/commit/f5bf5a014675d3b8ff5c1da9f4de42363f0ba2aa.patch";
            sha256 = "0cfpnp2y4izzqlsylia2h8y2bgi8yarwjp59kmx6bcvd2vvv5bcx";
          }
        ];
      });
  };

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
  hardware.pulseaudio.enable = true;

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    layout = "ca(multi)";
    videoDrivers = [ "nvidia" ];

    screenSection = ''
      Option "nvidiaXineramaInfoOrder" "DP-4"
      Option "metamodes" "DP-4: 3440x1440_120 +2560+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}, DP-2: 2560x1440_120 +0+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}"
    '';

    displayManager.lightdm.enable = true;

    displayManager.sessionCommands = let
      mouseName = "SINOWEALTH Wired Gaming Mouse";
    in ''
      numlockx on &
      # Enable autoscrolling
      mouseId="$(xinput list "${mouseName}" --id-only 2>/dev/null|grep -oP '(?<=id=)\d+')"
      xinput --set-prop "$mouseId" 'Evdev Wheel Emulation' 1
      xinput --set-prop "$mouseId" 'Evdev Wheel Emulation Button' 2
      xinput --set-prop "$mouseId" 'Evdev Wheel Emulation Axes' 6 7 4 5
      xinput --set-prop "$mouseId" 'Evdev Wheel Emulation Inertia' 7
      # Disable mouse acceleration
      xinput --set-prop "$mouseId" 'Device Accel Profile' -1
      xset m 0 0
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

  home-manager.users.peelz = (import ../../home-peelz/home.nix) { inherit stateVersion; };
}
