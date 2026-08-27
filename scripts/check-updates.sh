#!/bin/bash
# Print "<pkg> <current> <latest>" for every package whose upstream release is
# newer than the pkgver in its PKGBUILD. Prints nothing when all are current.
set -euo pipefail

src_dir=$(cd "$(dirname "$0")/.." && pwd)
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

"$src_dir/scripts/nvchecker-config.sh" "$work_dir" > "$work_dir/nvchecker.toml"

# nvchecker's plain log goes to stderr so stdout stays parseable JSON.
nvchecker -c "$work_dir/nvchecker.toml" --logger json > "$work_dir/versions.json"

# nvchecker exits 0 even when a source fails, and a failed source must not look
# like "everything is current".
failures=$(jq -r 'select(.level == "error") | "\(.name): \(.event)"' \
	"$work_dir/versions.json" | sort -u)
if [ -n "$failures" ]; then
	echo "check-updates: nvchecker failed for:" >&2
	echo "$failures" >&2
	exit 1
fi

while read -r pkg latest; do
	pkgbuild=$src_dir/pkgs/$pkg/PKGBUILD
	if [ ! -f "$pkgbuild" ]; then
		echo "check-updates: no PKGBUILD for $pkg" >&2
		exit 1
	fi

	current=$(set +u; . "$pkgbuild" > /dev/null 2>&1; echo "$pkgver")
	[ "$(vercmp "$latest" "$current")" -gt 0 ] || continue
	echo "$pkg $current $latest"
done < <(jq -r 'select(.version != null) | "\(.name) \(.version)"' "$work_dir/versions.json")
