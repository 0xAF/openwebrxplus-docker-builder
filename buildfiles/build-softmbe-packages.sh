#!/bin/bash
set -euxo pipefail

# shellcheck disable=SC1091
source /common.sh

export VERSION_CODENAME=bookworm
init_sources_cache

SCRIPT_VERSION="2"

case "${USE_LEGACY_MBELIB:-n}" in
	y)
		MBELIB_VARIANT="legacy"
		MBELIB_COMPONENT="mbelib-legacy-$SCRIPT_VERSION"
		MBELIB_REPO_URL="https://github.com/0xAF/mbelib"
		MBELIB_REF="HEAD"
		SOFTMBE_COMPONENT="codecserver-softmbe-legacy-$SCRIPT_VERSION"
		SOFTMBE_REF="config_quality_setting"
		;;
	n|"")
		MBELIB_VARIANT="neo-v2"
		MBELIB_COMPONENT="mbelib-neo-v2-$SCRIPT_VERSION"
		MBELIB_REPO_URL="https://github.com/arancormonk/mbelib-neo"
		MBELIB_REF="v2.0.0"
		SOFTMBE_COMPONENT="codecserver-softmbe-neo-v2-$SCRIPT_VERSION"
		SOFTMBE_REF="mbelib-neo-v2"
		;;
	*)
		echo "USE_LEGACY_MBELIB must be 'y' or 'n', got: ${USE_LEGACY_MBELIB}" >&2
		exit 2
		;;
esac

echo "+ SoftMBE mbelib variant: $MBELIB_VARIANT"

SOFTMBE_DEB_CACHE_DIR="$BUILD_CACHE/softmbe/$MBELIB_VARIANT/deb"
mkdir -p /deb "$SOFTMBE_DEB_CACHE_DIR"
printf '%s\n' "$MBELIB_VARIANT" > /deb/mbelib-variant

echo "+ init..."
apt_update_with_fallback 120
apt-get -y install --no-install-recommends wget gpg ca-certificates jq

echo "+ Add repos and update..."
wget -O - https://luarvique.github.io/ppa/openwebrx-plus.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/openwebrx-plus.gpg
echo "deb [signed-by=/etc/apt/trusted.gpg.d/openwebrx-plus.gpg] https://luarvique.github.io/ppa/bookworm ./" > /etc/apt/sources.list.d/openwebrx-plus.list
apt_update_with_fallback 120
apt upgrade -y

echo "+ Install dev packages..."
BUILD_PACKAGES=(git build-essential debhelper cmake libprotobuf-dev protobuf-compiler libcodecserver-dev wget gpg)
apt-get -y install --no-install-recommends "${BUILD_PACKAGES[@]}"

if [ "$MBELIB_VARIANT" = "legacy" ]; then
	if cache_component_should_build "$MBELIB_COMPONENT" "$MBELIB_REPO_URL" "$MBELIB_REF" "$SOFTMBE_DEB_CACHE_DIR/libmbe1_1.3*.deb" "$SOFTMBE_DEB_CACHE_DIR/libmbe-dev_1.3*.deb"; then
		echo "+ Build legacy MBELIB..."
		git_ensure_repo "mbelib" "$MBELIB_REPO_URL"
		git_checkout_ref "mbelib" "$MBELIB_REF"
		cd mbelib
		dpkg-buildpackage -b -us -uc
		cd ..
		mv -f libmbe1_1.3*.deb "$SOFTMBE_DEB_CACHE_DIR"/
		mv -f libmbe-dev_1.3*.deb "$SOFTMBE_DEB_CACHE_DIR"/
		cache_component_record "$MBELIB_COMPONENT" "$MBELIB_REPO_URL" "$MBELIB_REF" "$SCRIPT_VERSION" "$SOFTMBE_DEB_CACHE_DIR/libmbe1_1.3*.deb" "$SOFTMBE_DEB_CACHE_DIR/libmbe-dev_1.3*.deb"
	fi

	cp -f "$SOFTMBE_DEB_CACHE_DIR"/libmbe1_1.3*.deb /deb/
	cp -f "$SOFTMBE_DEB_CACHE_DIR"/libmbe-dev_1.3*.deb /deb/
	dpkg -i /deb/libmbe1_1.3*.deb /deb/libmbe-dev_1.3*.deb
	SOFTMBE_PACKAGE_GLOB="codecserver-driver-softmbe_0.0.1_*.deb"
else
	if cache_component_should_build "$MBELIB_COMPONENT" "$MBELIB_REPO_URL" "$MBELIB_REF" "$SOFTMBE_DEB_CACHE_DIR/libmbe-neo2_2.0.0_*.deb" "$SOFTMBE_DEB_CACHE_DIR/libmbe-neo-dev_2.0.0_*.deb"; then
		echo "+ Build mbelib-neo v2..."
		git_ensure_repo "mbelib-neo" "$MBELIB_REPO_URL"
		git_checkout_ref "mbelib-neo" "$MBELIB_REF"
		/prepare-mbelib-neo-debian.sh "mbelib-neo"
		cd mbelib-neo
		dpkg-buildpackage -b -us -uc
		cd ..
		mv -f libmbe-neo2_2.0.0_*.deb "$SOFTMBE_DEB_CACHE_DIR"/
		mv -f libmbe-neo-dev_2.0.0_*.deb "$SOFTMBE_DEB_CACHE_DIR"/
		cache_component_record "$MBELIB_COMPONENT" "$MBELIB_REPO_URL" "$MBELIB_REF" "$SCRIPT_VERSION" "$SOFTMBE_DEB_CACHE_DIR/libmbe-neo2_2.0.0_*.deb" "$SOFTMBE_DEB_CACHE_DIR/libmbe-neo-dev_2.0.0_*.deb"
	fi

	cp -f "$SOFTMBE_DEB_CACHE_DIR"/libmbe-neo2_2.0.0_*.deb /deb/
	cp -f "$SOFTMBE_DEB_CACHE_DIR"/libmbe-neo-dev_2.0.0_*.deb /deb/
	dpkg -i /deb/libmbe-neo2_2.0.0_*.deb /deb/libmbe-neo-dev_2.0.0_*.deb
	SOFTMBE_PACKAGE_GLOB="codecserver-driver-softmbe-neo_0.0.2_*.deb"
fi

SOFTMBE_REPO_URL="https://github.com/0xAF/codecserver-softmbe"
if cache_component_should_build "$SOFTMBE_COMPONENT" "$SOFTMBE_REPO_URL" "$SOFTMBE_REF" "$SOFTMBE_DEB_CACHE_DIR/$SOFTMBE_PACKAGE_GLOB"; then
	echo "+ Build codecserver-softmbe..."
	git_ensure_repo "codecserver-softmbe" "$SOFTMBE_REPO_URL"
	git_checkout_ref "codecserver-softmbe" "$SOFTMBE_REF"
	cd codecserver-softmbe
	dpkg-buildpackage -b -us -uc
	cd ..
	if [ "$MBELIB_VARIANT" = "legacy" ]; then
		mv -f codecserver-driver-softmbe_0.0.1_*.deb "$SOFTMBE_DEB_CACHE_DIR"/
	else
		mv -f codecserver-driver-softmbe-neo_0.0.2_*.deb "$SOFTMBE_DEB_CACHE_DIR"/
	fi
	cache_component_record "$SOFTMBE_COMPONENT" "$SOFTMBE_REPO_URL" "$SOFTMBE_REF" "$SCRIPT_VERSION" "$SOFTMBE_DEB_CACHE_DIR/$SOFTMBE_PACKAGE_GLOB"
fi

if [ "$MBELIB_VARIANT" = "legacy" ]; then
	cp -f "$SOFTMBE_DEB_CACHE_DIR"/codecserver-driver-softmbe_0.0.1_*.deb /deb/
else
	cp -f "$SOFTMBE_DEB_CACHE_DIR"/codecserver-driver-softmbe-neo_0.0.2_*.deb /deb/
fi

cd /deb
ls -la /deb
