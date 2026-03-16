#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /common.sh

SCRIPT_VERSION="1"
COMPONENT="rtl-sdr-blog"
REPO_URL="https://github.com/rtlsdrblog/rtl-sdr-blog"
REF="master"

if cache_component_should_build "$COMPONENT" "$REPO_URL" "$REF" "$BUILD_CACHE/librtlsdr0_*.deb" "$BUILD_CACHE/rtl-sdr_*.deb"; then
  pinfo "Install RTL-SDR Blog (v4)..."
  git_ensure_repo "rtl-sdr-blog" "$REPO_URL"
  git_checkout_ref "rtl-sdr-blog" "$REF"
  pushd rtl-sdr-blog
  dpkg-buildpackage -b --no-sign
  popd
  cache_component_record "$COMPONENT" "$REPO_URL" "$REF" "$SCRIPT_VERSION" "$BUILD_CACHE/librtlsdr0_*.deb" "$BUILD_CACHE/rtl-sdr_*.deb"
fi