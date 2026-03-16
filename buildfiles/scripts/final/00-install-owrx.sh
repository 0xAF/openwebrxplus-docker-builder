#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /common.sh

echo;echo;echo;echo;echo;echo;echo
pinfo "Building ${PRODUCT:-}:${OWRXVERSION:-}..."
pinfo "MAKEFLAGS: ${MAKEFLAGS:-}"
pinfo "BUILD_DATE: ${BUILD_DATE:-}"
pinfo "OWRX_REPO_COMMIT: ${OWRX_REPO_COMMIT:-}"
pinfo "FINAL_CACHE_BUSTER: ${FINAL_CACHE_BUSTER:-}"
pinfo "PLATFORM: ${PLATFORM}"
pinfo "PRODUCT: ${PRODUCT}"
pinfo "VERSION: ${OWRXVERSION}"

echo "${BUILD_DATE:-}" > /build-date
echo "${OWRX_REPO_COMMIT:-}" > /build-owrx-repo-commit
echo "${FINAL_CACHE_BUSTER:-}" > /build-final-cache-buster
echo "${PRODUCT:-}"-"${OWRXVERSION:-${BUILD_DATE}}" > /build-image

apt_update_with_fallback 120
apt upgrade -y

pinfo "Installing prebuilt deb packages..."
dpkg -i "$BUILD_CACHE"/librtlsdr0_*.deb
dpkg -i "$BUILD_CACHE"/rtl-sdr_*.deb
if [[ $(uname -m) != "armv7"* ]]; then
  dpkg -i "$BUILD_CACHE"/soapysdr0.8-module-airspyhf_*.deb
  dpkg -i "$BUILD_CACHE"/soapysdr-module-airspyhf_*.deb
fi
dpkg -i "$BUILD_CACHE"/soapysdr0.8-module-plutosdr_*.deb
dpkg -i "$BUILD_CACHE"/soapysdr-module-plutosdr_*.deb
dpkg -i "$BUILD_CACHE"/runds-connector_*.deb
dpkg -i "$BUILD_CACHE"/webrx-rade-decode-minimal*.deb

if [ -x "$BUILD_ROOTFS/usr/bin/satdump" ]; then
  pinfo "SatDump detected in source rootfs cache and will be included in final image."
else
  pwarn "SatDump binary not found in source rootfs cache."
fi

pinfo "Installing rest of the binaries from rootfs..."
cp -av "$BUILD_ROOTFS"/* /
sleep 3
ldconfig /etc/ld.so.conf.d

pinfo "This is a RELEASE (v${OWRXVERSION:-}) build."
DEBIAN_FRONTEND=noninteractive apt install -y --install-recommends openwebrx="${OWRXVERSION:-}"

grep -q 'custom.css' /usr/lib/python3/dist-packages/htdocs/index.html || sed -i 's|</head>|<link rel="stylesheet" type="text/css" href="static/css/custom.css" />\n</head>|' /usr/lib/python3/dist-packages/htdocs/index.html
ln -s /etc/openwebrx/custom.css /usr/lib/python3/dist-packages/htdocs/css/

mkdir -p /owrx-init
cp -a /etc/openwebrx /owrx-init/etc
cp -a /var/lib/openwebrx /owrx-init/var

chmod +x /run.sh

mkdir -p \
  /etc/s6-overlay/s6-rc.d/openwebrx/dependencies.d \
  /etc/s6-overlay/s6-rc.d/user/contents.d

echo longrun > /etc/s6-overlay/s6-rc.d/openwebrx/type
cat > /etc/s6-overlay/s6-rc.d/openwebrx/run << _EOF_
#!/command/execlineb -P
/run.sh
_EOF_
chmod +x /etc/s6-overlay/s6-rc.d/openwebrx/run
touch /etc/s6-overlay/s6-rc.d/user/contents.d/openwebrx

touch /etc/s6-overlay/s6-rc.d/openwebrx/dependencies.d/codecserver
touch /etc/s6-overlay/s6-rc.d/openwebrx/dependencies.d/sdrplay

pwarn "Tiny image..."
rm -f /etc/apt/apt.conf.d/51cache
apt clean
rm -rf /var/lib/apt/lists/*
find / -iname "*.a" -exec rm {} \;
find / -iname "*-old" -exec rm -rf {} \;

pok "Final image done."
