#!/usr/bin/env bash

nixcfg="$(realpath "$(dirname "$0")")"
host="$nixcfg/hosts/$(hostname)"
hostcfg="$host/configuration.nix"
nixpkgs_src="$host/sources/nixpkgs.nix"

if [[ ! -f "$hostcfg" ]]; then
  echo "host config not found: $hostcfg"
  exit 1
fi

nixpkgs="$(nix-instantiate --eval -E "import $nixpkgs_src" | sed 's/^"\(.*\)"$/\1/')"

echo "{ nixpkgs = \"$nixpkgs\"; hostcfg = \"$hostcfg\"; }" > "$host/.nixpath.nix"

nixos-rebuild \
  -I "nixpkgs=$nixpkgs" \
  -I "nixos-config=$hostcfg" \
  "$@"
