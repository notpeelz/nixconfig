#!/usr/bin/env bash

nixcfg="$(realpath "$(dirname "$0")")"
host="$(hostname)"
hostcfg="$nixcfg/hosts/$host/configuration.nix"

if [[ ! -f "$hostcfg" ]]; then
  echo "host config not found: $host"
  exit 1
fi

echo "{ cfg = \"$nixcfg\"; host = \"$host\"; }" > "$nixcfg/hosts/$host/.nixpath.nix"

nixos-rebuild \
  -I "nixpkgs=$nixcfg/sources/nixpkgs" \
  -I "nixos-config=$nixcfg/hosts/$host/configuration.nix" \
  "$@"
