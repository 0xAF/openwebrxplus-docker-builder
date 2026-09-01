#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /common.sh

SCRIPT_VERSION="1"
COMPONENT="satdump"
REPO_URL="https://github.com/altillimity/satdump.git"
REF="master"

# SatDump does not build on 32-bit ARM (armhf/armv7l) due to ABI issues
if [ "$(uname -m)" = "armv7l" ]; then
  pwarn "Skipping satdump build on armhf (armv7l) - not supported"
  exit 0
fi

if cache_component_should_build "$COMPONENT" "$REPO_URL" "$REF" \
  "$BUILD_ROOTFS/usr/bin/satdump" \
  "$BUILD_ROOTFS/usr/lib/satdump/plugins" \
  "$BUILD_ROOTFS/usr/local/lib/satdump/plugins"; then
  pinfo "Install satdump..."
  git_ensure_repo "satdump" "$REPO_URL"
  git_checkout_ref "satdump" "$REF"

  CMAKE_ARGS="-DBUILD_GUI=OFF" cmakebuild satdump

  mkdir -p "$BUILD_ROOTFS/usr/local/lib/satdump"
  ln -sf /usr/lib/satdump/plugins "$BUILD_ROOTFS/usr/local/lib/satdump/plugins"

  cache_component_record "$COMPONENT" "$REPO_URL" "$REF" "$SCRIPT_VERSION" \
    "$BUILD_ROOTFS/usr/bin/satdump" \
    "$BUILD_ROOTFS/usr/lib/satdump/plugins" \
    "$BUILD_ROOTFS/usr/local/lib/satdump/plugins"
fi
