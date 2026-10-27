#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /common.sh

if [[ $(uname -m) == "armv7"* ]]; then
  pinfo "Skipping AirSpyHF for armv7..."
  exit 0
fi

SCRIPT_VERSION="3"
COMPONENT="soapy-airspyhf-v${SCRIPT_VERSION}"
REPO_URL="https://github.com/pothosware/SoapyAirspyHF.git"
REF="master"

if cache_component_should_build "$COMPONENT" "$REPO_URL" "$REF" "$BUILD_CACHE/soapysdr0.8-module-airspyhf_*.deb" "$BUILD_CACHE/soapysdr-module-airspyhf_*.deb"; then
  pinfo "Install AirSpyHF..."
  git_ensure_repo "SoapyAirspyHF" "$REPO_URL"
  git_checkout_ref "SoapyAirspyHF" "$REF"
  pushd SoapyAirspyHF
  patch -p1 < /files/airspy/version.patch
  patch -p1 < /files/airspy/pkgconfig-library.patch
  dpkg-buildpackage -b
  popd
  require_artifacts "$BUILD_CACHE/soapysdr0.8-module-airspyhf_*.deb" "$BUILD_CACHE/soapysdr-module-airspyhf_*.deb"
  cache_component_record "$COMPONENT" "$REPO_URL" "$REF" "$SCRIPT_VERSION" "$BUILD_CACHE/soapysdr0.8-module-airspyhf_*.deb" "$BUILD_CACHE/soapysdr-module-airspyhf_*.deb"
fi
