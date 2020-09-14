with builtins;
final: super: {
  # fixes lutris build: https://github.com/NixOS/nixpkgs/pull/97432
  # allegro = super.allegro.override (old: { texinfo = super.texinfo6_5; });
}
