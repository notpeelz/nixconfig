{ stdenv, pkgs, fetchFromGitHub, makeWrapper }:

stdenv.mkDerivation rec {
  pname = "betterdiscordctl";
  version = "1.6.1";

  src = fetchFromGitHub {
    owner = "bb010g";
    repo = "betterdiscordctl";
    rev = "v${version}";
    sha256 = "0qbas7gbjpi688vmsq4yjbycc0g84zkilsfiikvjmj3nfcmy2xh6";
  };

  patches = [ ./nix-arg.patch ];

  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    install -D betterdiscordctl $out/bin/betterdiscordctl
    wrapProgram $out/bin/betterdiscordctl --add-flags "--nix"
  '';
}
