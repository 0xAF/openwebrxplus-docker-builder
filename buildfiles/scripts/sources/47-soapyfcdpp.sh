#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /common.sh

SCRIPT_VERSION="1"
COMPONENT="soapy-fcdpp"
REPO_URL="https://github.com/pothosware/SoapyFCDPP.git"
REF="soapy-fcdpp-0.1.1"

if cache_component_should_build "$COMPONENT" "$REPO_URL" "$REF" "$BUILD_ROOTFS/usr/local/lib/SoapySDR/modules*/libFCDPPSupport.so"; then
  pinfo "Install FCDPP..."
  git_ensure_repo "SoapyFCDPP" "$REPO_URL"
  git_checkout_ref "SoapyFCDPP" "$REF"
  cmakebuild SoapyFCDPP "$REF"
  cache_component_record "$COMPONENT" "$REPO_URL" "$REF" "$SCRIPT_VERSION" "$BUILD_ROOTFS/usr/local/lib/SoapySDR/modules*/libFCDPPSupport.so"
fi
