#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /common.sh

if [[ $(uname -m) == "armv7"* ]] || [[ $(uname -m) == "aarch64"* ]]; then
  pinfo "Skipping SoapySDDC for $(uname -m)..."
  exit 0
fi

SCRIPT_VERSION="1"
COMPONENT="soapy-sddc"
REPO_URL="https://github.com/ik1xpv/ExtIO_sddc.git"
REF="master"

if cache_component_should_build "$COMPONENT" "$REPO_URL" "$REF" \
  "$BUILD_ROOTFS/usr/local/lib/libsddc.so*" \
  "$BUILD_ROOTFS/usr/local/lib/SoapySDR/modules*/libSoapySDDC.so*"; then
  
  pinfo "Install SoapySDDC and libsddc..."
  git_ensure_repo "ExtIO_sddc" "$REPO_URL"
  git_checkout_ref "ExtIO_sddc" "$REF"
  
  cmakebuild ExtIO_sddc
  
  cache_component_record "$COMPONENT" "$REPO_URL" "$REF" "$SCRIPT_VERSION" \
    "$BUILD_ROOTFS/usr/local/lib/libsddc.so*" \
    "$BUILD_ROOTFS/usr/local/lib/SoapySDR/modules*/libSoapySDDC.so*"
fi