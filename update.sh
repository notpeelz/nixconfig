#!/usr/bin/env bash

nixcfg="$(realpath "$(dirname "$0")")"
hostname="$1"

if [[ -z "$hostname" ]]; then
  hostname="$(hostname)"
fi

host="$nixcfg/hosts/$hostname"

if [[ -z "$host" || ! -d "$host" ]]; then
  echo "Invalid host: $hostname"
  exit 1
fi

echo "Updating sources for $hostname"

for f in "$host/sources/"*.nix; do
  src="$(basename -s ".nix" "$f")"
  remote="$(grep -Po '^# remote \K.*' "$f")"
  branch="$(grep -Po '^# branch \K.*' "$f")"
  url="$(grep -Po 'url = "\K.*(?=")' "$f")"
  rev="$(basename -s ".tar.gz" "$url")"

  if [[ -z "$branch" ]]; then
    echo "Source $src is using a static rev, skipping."
    continue
  fi

  if [[ -z "$remote" ]]; then
    echo "Invalid remote for $src: $remote"
    continue
  fi

  echo "Fetching remote HEAD for $src"

  # convert pr number to something useable by git
  if [[ "${branch:0:1}" == "#" ]]; then
    branch="pull/${branch:1}/head"
  fi

  latest_rev="$(git ls-remote "$remote" "$branch" | grep -Po '^.*(?=\t)')"

  if [[ -z "$latest_rev" ]]; then
    echo "Failed to fetch latest rev for $src"
    echo
    continue
  fi

  # assuming the remote is github.com
  newurl="$remote/archive/$latest_rev.tar.gz"

  echo "Updating $src"
  if [[ "$url" == "$newurl" ]]; then
    echo "Up to date"
    echo
    continue
  fi

  sed_oldurl="$(echo "$url" | sed -e 's/[]\/$*.^[]/\\&/g')"
  sed_newurl="$(echo "$newurl" | sed -e 's/[]\/$*.^[]/\\&/g')"

  echo "Current rev: $rev"
  sha256="$(nix-prefetch-url --type sha256 --unpack "$newurl")"

  sed -i "s/url = \"$sed_oldurl\";/url = \"$sed_newurl\";/" "$f"
  sed -i "s/sha256 = \".*\";/sha256 = \"$sha256\";/" "$f"
  echo "Updated rev to $latest_rev"
  echo "Updated hash to $sha256"

  echo
done
