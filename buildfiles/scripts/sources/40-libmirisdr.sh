#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /common.sh

if [[ $(uname -m) == "armv7"* ]]; then
  pinfo "Skipping libmirisdr for armv7..."
  exit 0
fi

SCRIPT_VERSION="1"
COMPONENT="libmirisdr-5"
REPO_URL="https://github.com/ericek111/libmirisdr-5"
REF="master"

if cache_component_should_build "$COMPONENT" "$REPO_URL" "$REF" "$BUILD_ROOTFS/usr/local/lib/libmirisdr.so*"; then
  pinfo "Install libmirisdr-5..."
  git_ensure_repo "libmirisdr-5" "$REPO_URL"
  git_checkout_ref "libmirisdr-5" "$REF"
  cmakebuild libmirisdr-5
  cache_component_record "$COMPONENT" "$REPO_URL" "$REF" "$SCRIPT_VERSION" "$BUILD_ROOTFS/usr/local/lib/libmirisdr.so*"
fi
