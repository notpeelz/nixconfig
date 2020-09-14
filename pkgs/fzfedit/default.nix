{ pkgs }:

pkgs.writeShellScriptBin "fe" ''
  if [[ -z "$EDITOR" || ! "$(type -p "$EDITOR")" ]]; then
    echo '$EDITOR is undefined or invalid'
    exit 1
  fi

  out="$(${pkgs.fzf}/bin/fzf "$@")"
  retval=$?

  if [[ ! -f "$out" ]]; then
    echo "$out"
    exit $retval
  fi

  if [[ "$retval" -eq 0 && ! -z "$out" ]]; then
    "$EDITOR" "$out"
  fi
''
