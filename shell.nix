{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  name = "nixconfig-workspace";
  buildInputs = with pkgs; [
    (python3.withPackages (ppkgs: with ppkgs; [
      pip
      pylint
    ]))
  ];
}
