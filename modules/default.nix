{ lib, config, pkgs, ... }:

with lib;
{
  imports =
    let
      inherit (builtins) readDir;
      modules = map (name: import (./. + "/${name}"))
        (remove "default.nix"
          (attrNames
            (filterAttrs
              (n: v: v == "directory" || hasSuffix ".nix" n)
              (readDir ./.))));
    in modules;
}
