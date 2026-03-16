#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /common.sh

SCRIPT_VERSION="1"
COMPONENT="perseus-sdr"
REPO_URL="https://github.com/Microtelecom/libperseus-sdr.git"
REF="master"

if cache_component_should_build "$COMPONENT" "$REPO_URL" "$REF" \
  "$BUILD_ROOTFS/usr/local/bin/perseustest" \
  "$BUILD_ROOTFS/usr/local/lib/libperseus-sdr.so*"; then
  pinfo "Install PerseusSDR..."
  git_ensure_repo "libperseus-sdr" "$REPO_URL"
  git_checkout_ref "libperseus-sdr" "$REF"
  pushd libperseus-sdr
  ./bootstrap.sh
  ./configure
  make
  make install DESTDIR="$BUILD_ROOTFS"/
  popd
  cache_component_record "$COMPONENT" "$REPO_URL" "$REF" "$SCRIPT_VERSION" \
    "$BUILD_ROOTFS/usr/local/bin/perseustest" \
    "$BUILD_ROOTFS/usr/local/lib/libperseus-sdr.so*"
fi
