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
  };

  config = {
    users.users = mapAttrs (n: v: v.config) cfg.users;
    home-manager.users = mapAttrs
      (n: v: makeUser (../home + "/${n}") v.overrides)
      cfg.users;
  };
}
