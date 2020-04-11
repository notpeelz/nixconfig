{ pkgs }:

pkgs.writeShellScriptBin "nixos-eval-config" ''
  config_path="$1"
  if [[ -z "$config_path" ]]; then
    echo "Evaluating system config..."
    nix repl '<nixpkgs/nixos>'
  else
    [[ ! -f "$config_path" ]] && {
      echo "Invalid path: $config_path"
      exit 1
    }

    config_path="$(${pkgs.coreutils}/bin/realpath "$config_path")"
    echo "Evaluating config from $config_path"
    nix repl '<nixpkgs/nixos>' --argstr configuration "$config_path"
  fi
''
