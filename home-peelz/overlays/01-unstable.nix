final: super: with super.pkgs-unstable; {
  inherit
    rmtrash
    nix-query-tree-viewer
    bless
    vulnix;

  polybar = polybar.override (self: {
    pulseSupport = true;
  });
}
