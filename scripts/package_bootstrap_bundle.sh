#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <version>"
  exit 1
fi

VERSION="$1"
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
DIST_DIR="$ROOT_DIR/dist"
BUNDLE_DIR="$DIST_DIR/bootstrap-bundle-$VERSION"
ARCHIVE_PATH="$DIST_DIR/bootstrap-bundle-$VERSION.tar.gz"

rm -rf "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR"
mkdir -p "$DIST_DIR"

cp -R "$ROOT_DIR/bootstrap/scripts" "$BUNDLE_DIR/scripts"
cp -R "$ROOT_DIR/bootstrap/compose" "$BUNDLE_DIR/compose"
cp -R "$ROOT_DIR/bootstrap/systemd" "$BUNDLE_DIR/systemd"
cp -R "$ROOT_DIR/bootstrap/edge" "$BUNDLE_DIR/edge"
cp "$ROOT_DIR/scripts/install_bootstrap_bundle.sh" "$BUNDLE_DIR/install_bootstrap_bundle.sh"
printf '%s\n' "$VERSION" > "$BUNDLE_DIR/VERSION"

rm -f "$ARCHIVE_PATH"
tar -czf "$ARCHIVE_PATH" -C "$DIST_DIR" "bootstrap-bundle-$VERSION"
sha256sum "$ARCHIVE_PATH" > "$ARCHIVE_PATH.sha256"

printf '%s\n' "$ARCHIVE_PATH"
printf '%s\n' "$ARCHIVE_PATH.sha256"
