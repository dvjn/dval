# versioning

two kinds of package live in `pkgs/`, and they version differently.

## packages with an upstream

every `*-bin` package repackages a release from someone else.

- set `pkgver` to the upstream version, verbatim.
- start `pkgrel` at `1`. increment it when the packaging changes but the
  upstream version does not, such as a corrected `depends` array.
- reset `pkgrel` to `1` whenever `pkgver` changes.

`scripts/bump-pkgver.sh` applies all three rules, so the update workflow handles
those packages without help.

## first-party packages

`dval` has no upstream. this repository is the source, so the `dval` script and
the dependency lists in its metapackages are its content.

- increment `pkgver` whenever that content changes.
- reset `pkgrel` to `1` at the same time.
- increment `pkgrel` on its own only for a rebuild that changes nothing in this
  repository, such as a rebuild against a new soname.

adding a dependency is a content change. bump `pkgver` for it, so that
`pacman -Q` tells one build apart from another.

