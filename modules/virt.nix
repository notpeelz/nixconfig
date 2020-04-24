{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.my.virt;
in {
  options.my.virt = {
    enable = mkEnableOption "Virtualization programs";
  };

  config = mkIf cfg.enable {
    # Enable kvm
    virtualisation.libvirtd.enable = true;
    virtualisation.libvirtd.qemuPackage = pkgs.qemu_kvm;

    # Enable docker
    virtualisation.docker.enable = true;

    environment.systemPackages = with pkgs; [
      libvirt
      # UEFI firmware for QEMU and KVM
      OVMF
    ] ++ (optionals config.my.graphical.enable (with pkgs; [
      virt-manager
    ]));
  };
}
