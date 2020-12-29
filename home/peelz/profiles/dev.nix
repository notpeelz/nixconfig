{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.my.dev;
in {
  options.my.dev = {
    enable = mkEnableOption "Dev programs";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      direnv
      (vscode.overrideAttrs ({ buildInputs ? [], installPhase, ... }: {
        buildInputs = buildInputs ++ [ pkgs.makeWrapper ];
        # Add mono to PATH for ilspy-vscode
        installPhase = installPhase + ''
          wrapProgram $out/bin/code \
            --prefix PATH : "${stdenv.lib.makeBinPath [ pkgs.mono ]}"
        '';
      }))
      (symlinkJoin {
        name = "gdb-custom";
        paths = [
          gdb
        ];
        postBuild = ''
          # allows loading symbols from the nix store
          while IFS="" read -r l; do
            [[ ! -f "$l" ]] && continue
            source "$l/nix-support/setup-hook"
          done < ${pkgs.makeWrapper}/nix-support/propagated-build-inputs
          source ${pkgs.makeWrapper}/nix-support/setup-hook
          wrapProgram $out/bin/gdb \
            --add-flags '-iex "set auto-load safe-path /nix"'
        '';
      })
      ghidra-bin
      mitmproxy
    ];

    services.lorri.enable = true;
  };
}
