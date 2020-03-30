final: super:
with super.lib.attrsets; let
  inherit (builtins) readDir;
  packages = ../pkgs;
  names = (attrNames (filterAttrs (n: v: v == "directory") (readDir packages)));
  getPackage = name: super.callPackage (packages + "/${name}") { };
in genAttrs names getPackage
