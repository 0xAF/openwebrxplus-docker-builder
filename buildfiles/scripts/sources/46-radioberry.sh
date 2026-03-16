#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /common.sh

SCRIPT_VERSION="1"
COMPONENT="radioberry"
REPO_URL="https://github.com/pa3gsb/Radioberry-2.x"
REF="master"

if cache_component_should_build "$COMPONENT" "$REPO_URL" "$REF" "$BUILD_ROOTFS/usr/local/lib/SoapySDR/modules*/libSoapyRadioberrySDR.so"; then
  pinfo "Install RadioberrySDR..."
  git_ensure_repo "Radioberry-2.x" "$REPO_URL"
  git_checkout_ref "Radioberry-2.x" "$REF"
  pushd Radioberry-2.x/SBC/rpi-4
  cmakebuild SoapyRadioberrySDR
  popd
  cache_component_record "$COMPONENT" "$REPO_URL" "$REF" "$SCRIPT_VERSION" "$BUILD_ROOTFS/usr/local/lib/SoapySDR/modules*/libSoapyRadioberrySDR.so"
fi
