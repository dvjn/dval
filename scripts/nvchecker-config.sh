#!/bin/sh
# Merge every pkgs/*/.nvchecker.toml into one config on stdout.
# GITHUB_TOKEN, when set, is written to the keyfile so the github source is not
# rate limited and can read releases.
set -eu

src_dir=$(cd "$(dirname "$0")/.." && pwd)
work_dir=${1:?usage: nvchecker-config.sh <work-dir>}

mkdir -p "$work_dir"

if [ -n "${GITHUB_TOKEN:-}" ]; then
	keyfile=$work_dir/keys.toml
	printf '[keys]\ngithub = "%s"\n' "$GITHUB_TOKEN" > "$keyfile"
	chmod 600 "$keyfile"
	printf '[__config__]\nkeyfile = "%s"\n\n' "$keyfile"
fi

for config in "$src_dir"/pkgs/*/.nvchecker.toml; do
	[ -e "$config" ] || continue
	cat "$config"
	echo
done
