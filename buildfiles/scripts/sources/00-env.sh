#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /common.sh

export PATH=/usr/local/go/bin:$PATH
mkdir -p /go /gocache
export GOPATH=/go
export GOCACHE=/gocache

echo;echo;echo;echo;echo;echo;echo
pinfo "Building from sources..."
pinfo "MAKEFLAGS: ${MAKEFLAGS:-}"
pinfo "PLATFORM: ${PLATFORM}"

VERSION_CODENAME="$(detect_version_codename)"
export VERSION_CODENAME
init_sources_cache

case "$VERSION_CODENAME" in
  bookworm)
    pinfo "Detected Debian Bookworm."
    OS_PACKAGES='libvolk2-dev'
    ;;
  trixie)
    pinfo "Detected Debian Trixie."
    OS_PACKAGES='libvolk-dev'
    ;;
  *)
    perror "Unknown or unsupported (Debian) VERSION_CODENAME: $VERSION_CODENAME"
    exit 1
    ;;
esac

pinfo "Install dev packages..."
BUILD_PACKAGES="
  git
  cmake
  make
  patch
  wget
  sudo
  libusb-1.0-0-dev
  libsoapysdr-dev
  debhelper
  build-essential
  pkg-config
  libairspyhf-dev
  dpkg-dev
  xxd
  libpopt-dev
  libiio-dev
  libad9361-dev
  libhidapi-dev
  libasound2-dev
  libfftw3-dev
  libowrx-connector-dev
  libboost-dev
  libboost-program-options-dev
  libboost-log-dev
  libboost-regex-dev
  gfortran
  libcurl4-openssl-dev
  libsqlite3-dev
  qt5-qmake
  libpulse-dev
  libncurses-dev
  libliquid-dev
  libconfig++-dev
  libpng-dev
  libtiff-dev
  libjemalloc-dev
  libnng-dev
  libzstd-dev
  libomp-dev
  ocl-icd-opencl-dev
  libglfw3-dev
  $OS_PACKAGES
"

apt_update_with_fallback 120
# shellcheck disable=SC2086
apt install -y --no-install-recommends $BUILD_PACKAGES

mkdir -p "$BUILD_ROOTFS"/usr/local/bin
