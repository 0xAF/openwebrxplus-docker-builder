#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /common.sh

SCRIPT_VERSION="1"
COMPONENT="soapy-plutosdr"
REPO_URL="https://github.com/pothosware/SoapyPlutoSDR.git"
REF="master"

if cache_component_should_build "$COMPONENT" "$REPO_URL" "$REF" "$BUILD_CACHE/soapysdr0.8-module-plutosdr_*.deb" "$BUILD_CACHE/soapysdr-module-plutosdr_*.deb"; then
  pinfo "Install PlutoSDR..."
  git_ensure_repo "SoapyPlutoSDR" "$REPO_URL"
  git_checkout_ref "SoapyPlutoSDR" "$REF"
  pushd SoapyPlutoSDR
  patch -p1 < /files/plutosdr/version.patch || true
  dpkg-buildpackage -b
  popd
  cache_component_record "$COMPONENT" "$REPO_URL" "$REF" "$SCRIPT_VERSION" "$BUILD_CACHE/soapysdr0.8-module-plutosdr_*.deb" "$BUILD_CACHE/soapysdr-module-plutosdr_*.deb"
fi
