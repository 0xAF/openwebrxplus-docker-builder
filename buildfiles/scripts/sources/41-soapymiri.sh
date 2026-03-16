#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /common.sh

if [[ $(uname -m) == "armv7"* ]]; then
  pinfo "Skipping SoapyMiri for armv7..."
  exit 0
fi

SCRIPT_VERSION="1"
COMPONENT="soapy-miri"
REPO_URL="https://github.com/ericek111/SoapyMiri"
REF="master"

if cache_component_should_build "$COMPONENT" "$REPO_URL" "$REF" "$BUILD_ROOTFS/usr/local/lib/SoapySDR/modules0.8/libsoapyMiriSupport.so"; then
  pinfo "Install SoapyMiri..."
  git_ensure_repo "SoapyMiri" "$REPO_URL"
  git_checkout_ref "SoapyMiri" "$REF"
  cmakebuild SoapyMiri
  cache_component_record "$COMPONENT" "$REPO_URL" "$REF" "$SCRIPT_VERSION" "$BUILD_ROOTFS/usr/local/lib/SoapySDR/modules0.8/libsoapyMiriSupport.so"
fi
