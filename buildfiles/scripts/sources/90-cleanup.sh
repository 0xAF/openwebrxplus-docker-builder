#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /common.sh

rm -f "$BUILD_CACHE"/*.buildinfo
rm -f "$BUILD_CACHE"/*.changes

# Copy artifacts to the layer filesystem so the final stage can use
# COPY --from=sources instead of relying on the cache mount (which can
# desync from the layer cache and cause missing-file errors).
pinfo "Copying build artifacts to layer filesystem..."
pinfo "BUILD_CACHE=$BUILD_CACHE"
pinfo "BUILD_ROOTFS=$BUILD_ROOTFS"
pinfo "Contents of BUILD_CACHE:"
ls -la "$BUILD_CACHE"/ || true
pinfo "Deb files in BUILD_CACHE:"
find "$BUILD_CACHE" -name '*.deb' -ls 2>/dev/null || true
pinfo "Contents of BUILD_ROOTFS:"
ls -la "$BUILD_ROOTFS"/ 2>/dev/null || true

mkdir -p /build_artifacts
cp "$BUILD_CACHE"/*.deb /build_artifacts/ 2>/dev/null || true
if [ -d "$BUILD_ROOTFS" ] && [ -n "$(ls -A "$BUILD_ROOTFS" 2>/dev/null)" ]; then
  cp -a "$BUILD_ROOTFS" /build_artifacts/rootfs
fi

pinfo "Contents of /build_artifacts:"
ls -laR /build_artifacts/ || true

pok "Sources done."
