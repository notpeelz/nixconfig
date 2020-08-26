{ lib, config, pkgs, ... }:

with lib;
{
  imports =
    let
      inherit (builtins) readDir;
      modules = map
        (name: import (./. + "/${name}"))
        (attrNames (filterAttrs
          (n: v: n != "default.nix" &&
            (v == "directory" || hasSuffix ".nix" n))
            (readDir ./.)));
    in modules;
}
