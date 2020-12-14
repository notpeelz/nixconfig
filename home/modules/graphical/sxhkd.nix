{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.my.graphical.services.sxhkd;
  hotkeySubmodule = types.submodule {
    options = {
      hotkey = mkOption {
        type = types.str;
      };
      cmd = mkOption {
        type = types.oneOf (with types; [ str package ]);
      };
    };
  };
in {
  options.my.graphical.services.sxhkd = {
    enable = mkEnableOption "simple X hotkey daemon";
    shell = mkOption {
      type = types.str;
      default = "${pkgs.bash}/bin/bash";
      description = ''
        The shell to use for executing commands.
      '';
    };
    envVars = mkOption {
      type = types.attrs;
      internal = true;
      default = {};
      description = ''
        Environment variables passed to sxhkd and its config.
      '';
    };
    extraPath = mkOption {
      type = types.envVar;
      default = "";
      description = ''
        Extra entries to be prepended to sxhkd's <envar>PATH</envar>.
      '';
    };
    hotkeys = mkOption {
      type = types.listOf hotkeySubmodule;
      default = [];
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ sxhkd ];

    systemd.user.services.sxhkd = let
      sxhkdrc = let
        sxhkdConfig = let
          buildInputs = with pkgs; [
            python3
          ];
        in pkgs.runCommand "sxhkd-config" {
          # structuredAttrs would be nice here, but we can do without it
          # __structuredAttrs = true;
          hotkeys = let
            mkScript = i: { hotkey, ... }: pkgs.writeTextFile {
              name = "sxhkd-raw-hotkey-${toString i}";
              executable = false;
              text = hotkey;
            };
          in imap0 mkScript cfg.hotkeys;
          scripts = let
            mkScript = i: { cmd, ... }: pkgs.writeTextFile {
              name = "sxhkd-raw-script-${toString i}";
              executable = false;
              text = cmd;
            };
          in imap0 mkScript cfg.hotkeys;
        } ''
          export PATH=${lib.escapeShellArg (lib.makeBinPath buildInputs)}''${PATH:+':'}"$PATH"

          hotkeysArray=($hotkeys)
          scriptsArray=($scripts)
          mkdir -p $out

          hotkeyCount="''${#hotkeysArray[@]}"
          numberOfDigits="''${#hotkeyCount}"
          for i in "''${!hotkeysArray[@]}"; do
            cd $out

            hkdir="hotkey-$(printf "%0''${numberOfDigits}d" "$i")"
            mkdir -p $hkdir

            cd $hkdir
            python3 ${./split_sxhkd_hotkey.py} \
              3< "''${hotkeysArray[i]}" \
              4< "''${scriptsArray[i]}"
            retval=$?
            if [[ $retval -ne 0 ]]; then
              echo -e "failed processing sxhkd hotkey\n  ''${hotkeysArray[i]}\n  ''${scriptsArray[i]}"
              exit $retval
            fi

            for f in *.sh; do
              [[ -z "$f" ]] && continue
              [[ ! -f "$f" ]] && continue
              # extract the hotkey
              sed 's/^# //;3q;d' "$f" >> $out/sxhkdrc
              # indentation
              echo -n '  ' >> $out/sxhkdrc
              # script to execute
              echo "$PWD/$f" >> $out/sxhkdrc
              echo >> $out/sxhkdrc
            done
          done
        '';
      in "${sxhkdConfig}/sxhkdrc";
    in {
      Unit = {
        Description = "X hotkey daemon";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        # Inherit the session env vars
        EnvironmentFile = "%h/.xsession_env";
        # These override the env vars that were set at session startup
        # through .xsession_env
        Environment = lib.attrValues (lib.mapAttrs
          (k: v: "${k}=${escapeShellArg v}")
          (cfg.envVars // {
            PATH = let
              userPkgs = makeBinPath [
                # This is important! If we don't have this, the PATH from
                # .xsession_env would never get updated when switching
                # configuration
                config.home.profileDirectory
                # If the user doesn't have bash in its PATH, supply it for them
                pkgs.bash
              ];
            in "${cfg.extraPath}" + (lib.optionalString (cfg.extraPath != "") ":")
              + userPkgs;
            # Not technically necessary since we're wrapping every command in
            # a separate bash script... but at least it means we're not
            # implicitly relying on bourne shell.
            SXHKD_SHELL = cfg.shell;
          }));
        ExecStart = "${pkgs.sxhkd}/bin/sxhkd -m -1 -c ${sxhkdrc}";
        # Prevent killing child processes when restarting sxhkd
        KillMode = "process";
        Restart = "on-failure";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
