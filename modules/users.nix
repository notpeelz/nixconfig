{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.my.users;

  makeUser = path: overrides:
    let
      user = import path {
        inherit (config.system) stateVersion;
        inherit (pkgs) channelSources;
      };
    in setFunctionArgs (args: recursiveUpdate (user args) overrides)
      (functionArgs user);

  userModule = types.submodule ({ name, ... }: {
    options = {
      config = mkOption {
        type = types.attrs;
        default = {};
      };
      overrides = mkOption {
        type = types.attrs;
        default = {};
      };
    };
  });
in {
  options.my.users = {
    users = mkOption {
      type = types.attrsOf userModule;
      default = {};
    };
    globalOverrides = mkOption {
      type = types.attrs;
      default = {};
    };
  };

  config = {
    users.users = mapAttrs (n: v: v.config) cfg.users;
    home-manager.users =
      mapAttrs (n: v: let
        overrides = foldl (a: b: recursiveUpdate a b) {} [
          # Enable my.graphical for the user if it's enabled on the host
          (optionalAttrs config.my.graphical.enable {
            my.graphical.enable = mkDefault true;
          })
          # Merge user-specific overrides with global overrides
          (recursiveUpdate cfg.globalOverrides v.overrides)
        ];
      in makeUser (../home + "/${n}") overrides) cfg.users;
  };
}
