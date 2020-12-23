{ pkgs ? import <nixpkgs> {}, stdenv ? pkgs.stdenv, ... }:

stdenv.mkDerivation {
  name = "paprop";
  src = ./.;
  nativeBuildInputs = with pkgs; [
    (symlinkJoin {
      name = "cmake";
      paths = [
        cmake
      ];
      postBuild = ''
        cp ${extra-cmake-modules}/share/ECM/find-modules/FindPulseAudio.cmake $out/share/cmake-*/Modules/
      '';
    })
  ];
  buildInputs = with pkgs; [
    pulseaudio
  ];
  preBuildPhase = ''
    mkdir build
    cd build
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp paprop $out/bin
  '';
  separateDebugInfo = true;
}
