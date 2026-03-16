#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /common.sh

if [[ $(uname -m) == "armv7"* ]]; then
  pinfo "Skipping SoapyHydraSDR for armv7..."
  exit 0
fi

SCRIPT_VERSION="1"
COMPONENT="soapy-hydrasdr"
REPO_URL="https://github.com/hydrasdr/SoapyHydraSDR"
REF="master"

if cache_component_should_build "$COMPONENT" "$REPO_URL" "$REF" "$BUILD_ROOTFS/usr/local/lib/SoapySDR/modules0.8/libSoapyHydraSDR.so"; then
  pinfo "Install SoapyHydraSDR..."
  git_ensure_repo "SoapyHydraSDR" "$REPO_URL"
  git_checkout_ref "SoapyHydraSDR" "$REF"
  cmakebuild SoapyHydraSDR
  rm -f "$BUILD_ROOTFS"/usr/lib/x86_64-linux-gnu/SoapySDR/modules0.8/libSoapyHydraSDR.so || true
  cache_component_record "$COMPONENT" "$REPO_URL" "$REF" "$SCRIPT_VERSION" "$BUILD_ROOTFS/usr/local/lib/SoapySDR/modules0.8/libSoapyHydraSDR.so"
fi
