{ pkgs }:

let
  p = "${pkgs.coreutils}/bin";
in pkgs.writeShellScriptBin "whichpath" ''
  type -p "$1" &>/dev/null && exists=1
  if [[ -z "$1" || ! "$exists" -eq 1 ]]; then
    echo "syntax: $(basename "$0") <program>"
    exit 1
  fi

  ${p}/dirname $(${p}/realpath $(type -p "$1"))
''
