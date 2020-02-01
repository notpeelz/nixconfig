{ ... }:

{
  environment.etc."machine-id".source = "/persistent/etc/machine-id";
  environment.etc.NIXOS_LUSTRATE.source = "/persistent/etc/NIXOS_LUSTRATE";

  # Persistence of nixos config files
  fileSystems."/etc/nixos" = {
    device = "/persistent/etc/nixos";
    options = [ "bind" ];
  };

  # Persistence of home folder
  fileSystems."/home/peelz" = {
    device = "/persistent/home/peelz";
    options = [ "bind" ];
  };

  # Persistence of root home folder
  fileSystems."/root" = {
    device = "/persistent/root";
    options = [ "bind" ];
  };
}
