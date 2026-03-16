#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /common.sh

SCRIPT_VERSION="1"
COMPONENT="soapy-afedri"
REPO_URL="https://github.com/alexander-sholohov/SoapyAfedri.git"
REF="master"

if cache_component_should_build "$COMPONENT" "$REPO_URL" "$REF" "$BUILD_ROOTFS/usr/local/lib/SoapySDR/modules*/libafedriDevice.so"; then
  pinfo "Install SoapyAfedri..."
  git_ensure_repo "SoapyAfedri" "$REPO_URL"
  git_checkout_ref "SoapyAfedri" "$REF"
  cmakebuild SoapyAfedri
  cache_component_record "$COMPONENT" "$REPO_URL" "$REF" "$SCRIPT_VERSION" "$BUILD_ROOTFS/usr/local/lib/SoapySDR/modules*/libafedriDevice.so"
fi
