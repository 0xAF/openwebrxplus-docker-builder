#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /common.sh

if [[ $(uname -m) == "armv7"* ]]; then
  pinfo "Skipping libhydrasdr for armv7..."
  exit 0
fi

SCRIPT_VERSION="1"
COMPONENT="libhydrasdr"
REPO_URL="https://github.com/hydrasdr/rfone_host"
REF="master"

if cache_component_should_build "$COMPONENT" "$REPO_URL" "$REF" "$BUILD_ROOTFS/usr/local/lib/libhydrasdr.so*"; then
  pinfo "Install libhydrasdr (rfone_host)..."
  git_ensure_repo "rfone_host" "$REPO_URL"
  git_checkout_ref "rfone_host" "$REF"
  cmakebuild rfone_host
  cache_component_record "$COMPONENT" "$REPO_URL" "$REF" "$SCRIPT_VERSION" "$BUILD_ROOTFS/usr/local/lib/libhydrasdr.so*"
fi
