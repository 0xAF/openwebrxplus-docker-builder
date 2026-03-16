#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /common.sh

SCRIPT_VERSION="1"
COMPONENT="codec2-freedv"
REPO_URL="https://github.com/drowe67/codec2.git"
REF="1.2.0"

if cache_component_should_build "$COMPONENT" "$REPO_URL" "$REF" \
  "$BUILD_ROOTFS/usr/local/bin/freedv_rx" \
  "$BUILD_ROOTFS/usr/local/lib/libcodec2.so*"; then
  pinfo "Install FreeDV..."
  git_ensure_repo "codec2" "$REPO_URL"
  git_checkout_ref "codec2" "$REF"

  pushd codec2
  rm -rf build
  mkdir -p build
  cd build
  cmake ..
  make
  make install DESTDIR="$BUILD_ROOTFS"/
  install -D -m 0755 src/freedv_rx "$BUILD_ROOTFS"/usr/local/bin
  popd

  cache_component_record "$COMPONENT" "$REPO_URL" "$REF" "$SCRIPT_VERSION" \
    "$BUILD_ROOTFS/usr/local/bin/freedv_rx" \
    "$BUILD_ROOTFS/usr/local/lib/libcodec2.so*"
fi

if [ -d "$BUILD_ROOTFS/usr/local/include" ]; then
  cp -a "$BUILD_ROOTFS"/usr/local/include/* /usr/local/include/ || true
fi
if [ -d "$BUILD_ROOTFS/usr/local/lib" ]; then
  cp -a "$BUILD_ROOTFS"/usr/local/lib/* /usr/local/lib/ || true
fi
