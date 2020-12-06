final: super: let
  nixpkgs-src = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/f2211de99ebd4c568e848649ef70bf5548d8ba6a.tar.gz";
  };
  nixpkgs = import nixpkgs-src {
    inherit (super) config;
  };
in {
  inherit (nixpkgs) obs-v4l2sink;
}
