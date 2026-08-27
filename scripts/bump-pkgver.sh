#!/bin/bash
# Set a package to a new pkgver, refresh every sha256sums array, and regenerate
# .SRCINFO. Checksums are generated once per arch in the PKGBUILD, because
# makepkg -g only emits the arrays that apply to the CARCH it is configured for.
set -euo pipefail

src_dir=$(cd "$(dirname "$0")/.." && pwd)
pkg=${1:?usage: bump-pkgver.sh <pkg> <version>}
version=${2:?usage: bump-pkgver.sh <pkg> <version>}

pkg_dir=$src_dir/pkgs/$pkg
[ -f "$pkg_dir/PKGBUILD" ] || { echo "bump-pkgver: no package: $pkg" >&2; exit 1; }

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

cd "$pkg_dir"

sed -i -e "s/^pkgver=.*/pkgver=$version/" -e "s/^pkgrel=.*/pkgrel=1/" PKGBUILD

arches=$(set +u; . ./PKGBUILD > /dev/null 2>&1; echo "${arch[@]}")
for target in $arches; do
	[ "$target" != any ] || continue
	# SRCDEST and BUILDDIR keep the downloads out of the package directory.
	{
		sed "s/^CARCH=.*/CARCH=$target/" /etc/makepkg.conf
		printf 'SRCDEST=%s\nBUILDDIR=%s\n' "$work_dir/src" "$work_dir/build"
	} > "$work_dir/makepkg-$target.conf"
	makepkg -g --config "$work_dir/makepkg-$target.conf" >> "$work_dir/sums"
done

# Keep the first block seen for each array name; the arch-independent
# sha256sums repeats identically for every arch.
awk '
	/^[a-z0-9_]+sums(_[a-z0-9_]+)?=\(/ {
		name = substr($0, 1, index($0, "=") - 1)
		keep = !(name in seen)
		seen[name] = 1
		if (keep) blocks[name] = $0
		current = name
		if ($0 ~ /\)[[:space:]]*$/) current = ""
		next
	}
	current != "" {
		if (keep) blocks[current] = blocks[current] "\\n" $0
		if ($0 ~ /\)[[:space:]]*$/) current = ""
		next
	}
	END { for (name in blocks) print name "\t" blocks[name] }
' "$work_dir/sums" | while IFS=$'\t' read -r name block; do
	printf '%b\n' "$block" > "$work_dir/block"
	awk -v name="$name" -v block_file="$work_dir/block" '
		index($0, name "=(") == 1 {
			while ((getline line < block_file) > 0) print line
			close(block_file)
			if ($0 !~ /\)[[:space:]]*$/) skipping = 1
			next
		}
		skipping { if ($0 ~ /\)[[:space:]]*$/) skipping = 0; next }
		{ print }
	' PKGBUILD > "$work_dir/PKGBUILD.new"
	mv "$work_dir/PKGBUILD.new" PKGBUILD
done

[ ! -f .SRCINFO ] || makepkg --printsrcinfo > .SRCINFO

echo "bumped $pkg to $version"
