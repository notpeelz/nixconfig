#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

export hardeningDisable=all
debug="$(nix-build --quiet --no-out-link -A debug)/lib/debug/paprop"
bin="$(nix-build --quiet --no-out-link)/bin/paprop"
echo $bin

# gdb -iex "set auto-load safe-path /nix"
gdb -iex "dir $DIR" -iex "add-symbol-file $debug" $bin --args "$bin" "${@}" #./coredump.bin
