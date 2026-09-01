#!/bin/bash
set -euo pipefail

SOURCE_DIR="${1:?Usage: prepare-mbelib-neo-debian.sh SOURCE_DIR [TEMPLATE_DIR]}"
TEMPLATE_DIR="${2:-/mbelib-neo-debian}"

if [ ! -f "$SOURCE_DIR/CMakeLists.txt" ] || [ ! -f "$SOURCE_DIR/include/mbelib-neo/mbelib.h" ]; then
    echo "Not an mbelib-neo source tree: $SOURCE_DIR" >&2
    exit 1
fi

if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "Debian packaging template not found: $TEMPLATE_DIR" >&2
    exit 1
fi

if [ -e "$SOURCE_DIR/debian" ]; then
    echo "Refusing to overwrite an existing debian directory in $SOURCE_DIR" >&2
    exit 1
fi

install -d "$SOURCE_DIR/debian"
cp -a "$TEMPLATE_DIR"/. "$SOURCE_DIR/debian"/
chmod 0755 "$SOURCE_DIR/debian/rules"

echo "Prepared mbelib-neo Debian packaging in $SOURCE_DIR/debian"
