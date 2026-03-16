#!/bin/bash
set -euxo pipefail

# shellcheck disable=SC1091
source /common.sh

export VERSION_CODENAME=bookworm
init_sources_cache

SCRIPT_VERSION="1"

SOFTMBE_DEB_CACHE_DIR="$BUILD_CACHE/softmbe/deb"
mkdir -p /deb "$SOFTMBE_DEB_CACHE_DIR"

echo "+ init..."
apt_update_with_fallback 120
apt-get -y install --no-install-recommends wget gpg ca-certificates jq

echo "+ Add repos and update..."
wget -O - https://luarvique.github.io/ppa/openwebrx-plus.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/openwebrx-plus.gpg
echo "deb [signed-by=/etc/apt/trusted.gpg.d/openwebrx-plus.gpg] https://luarvique.github.io/ppa/bookworm ./" > /etc/apt/sources.list.d/openwebrx-plus.list
apt_update_with_fallback 120
apt upgrade -y

echo "+ Install dev packages..."
BUILD_PACKAGES="git build-essential debhelper cmake libprotobuf-dev protobuf-compiler libcodecserver-dev wget gpg"
apt-get -y install --no-install-recommends $BUILD_PACKAGES

COMPONENT="mbelib"
REPO_URL="https://github.com/0xAF/mbelib"
REF="HEAD"
if cache_component_should_build "$COMPONENT" "$REPO_URL" "$REF" "$SOFTMBE_DEB_CACHE_DIR/libmbe1_1.3*.deb" "$SOFTMBE_DEB_CACHE_DIR/libmbe-dev_1.3*.deb"; then
	echo "+ Build MBELIB..."
	git_ensure_repo "mbelib" "$REPO_URL"
	git_checkout_ref "mbelib" "$REF"
	cd mbelib
	dpkg-buildpackage
	cd ..
	mv -f libmbe1_1.3*.deb "$SOFTMBE_DEB_CACHE_DIR"/
	mv -f libmbe-dev_1.3*.deb "$SOFTMBE_DEB_CACHE_DIR"/
	cache_component_record "$COMPONENT" "$REPO_URL" "$REF" "$SCRIPT_VERSION" "$SOFTMBE_DEB_CACHE_DIR/libmbe1_1.3*.deb" "$SOFTMBE_DEB_CACHE_DIR/libmbe-dev_1.3*.deb"
fi

cp -f "$SOFTMBE_DEB_CACHE_DIR"/libmbe1_1.3*.deb /deb/
cp -f "$SOFTMBE_DEB_CACHE_DIR"/libmbe-dev_1.3*.deb /deb/

dpkg -i /deb/libmbe1_1.3*.deb /deb/libmbe-dev_1.3*.deb

COMPONENT="codecserver-softmbe"
REPO_URL="https://github.com/0xAF/codecserver-softmbe"
REF="HEAD"
if cache_component_should_build "$COMPONENT" "$REPO_URL" "$REF" "$SOFTMBE_DEB_CACHE_DIR/codecserver-driver-softmbe_0.0.1_*.deb"; then
	echo "+ Build codecserver-softmbe..."
	git_ensure_repo "codecserver-softmbe" "$REPO_URL"
	git_checkout_ref "codecserver-softmbe" "$REF"
	cd codecserver-softmbe
	dpkg-buildpackage
	cd ..
	mv -f codecserver-driver-softmbe_0.0.1_*.deb "$SOFTMBE_DEB_CACHE_DIR"/
	cache_component_record "$COMPONENT" "$REPO_URL" "$REF" "$SCRIPT_VERSION" "$SOFTMBE_DEB_CACHE_DIR/codecserver-driver-softmbe_0.0.1_*.deb"
fi

cp -f "$SOFTMBE_DEB_CACHE_DIR"/codecserver-driver-softmbe_0.0.1_*.deb /deb/

cd /deb
ls -la /deb
