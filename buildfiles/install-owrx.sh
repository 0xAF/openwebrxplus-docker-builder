#!/bin/bash
set -euo pipefail

source /tmp/common.sh

echo;echo;echo;echo;echo;echo;echo
pinfo "Building ${PRODUCT:-}:${OWRXVERSION:-}..."
pinfo "MAKEFLAGS: ${MAKEFLAGS:-}"
pinfo "BUILD_DATE: ${BUILD_DATE:-}"
pinfo "PLATFORM: ${PLATFORM}"
pinfo "PRODUCT: ${PRODUCT}"
pinfo "VERSION: ${OWRXVERSION}"

echo ${BUILD_DATE:-} > /build-date
echo ${PRODUCT:-}-${OWRXVERSION:-${BUILD_DATE}} > /build-image

apt update

pinfo "Installing prebuilt deb packages..."
dpkg -i $BUILD_CACHE/librtlsdr0_*.deb
#dpkg -i $BUILD_CACHE/librtlsdr-dev_*.deb
dpkg -i $BUILD_CACHE/rtl-sdr_*.deb
dpkg -i $BUILD_CACHE/soapysdr0.8-module-airspyhf_*.deb
dpkg -i $BUILD_CACHE/soapysdr-module-airspyhf_*.deb
dpkg -i $BUILD_CACHE/soapysdr0.8-module-plutosdr_*.deb
dpkg -i $BUILD_CACHE/soapysdr-module-plutosdr_*.deb
dpkg -i $BUILD_CACHE/runds-connector_*.deb

pinfo "Installing rest of the binaries from rootfs..."
cp -a $BUILD_ROOTFS/* /
ldconfig /etc/ld.so.conf.d

pinfo "This is a RELEASE build."
DEBIAN_FRONTEND=noninteractive apt install -y --install-recommends openwebrx=${OWRXVERSION:-}
#--install-suggests

# add custom.css to OWRX
grep -q 'custom.css' /usr/lib/python3/dist-packages/htdocs/index.html || sed -i 's|</head>|<link rel="stylesheet" type="text/css" href="static/css/custom.css" />\n</head>|' /usr/lib/python3/dist-packages/htdocs/index.html
ln -s /etc/openwebrx/custom.css /usr/lib/python3/dist-packages/htdocs/css/

cp -a /etc/openwebrx /tmp/owrx-etc
cp -a /var/lib/openwebrx /tmp/owrx-var

chmod +x /run.sh

mkdir -p \
  /etc/s6-overlay/s6-rc.d/openwebrx/dependencies.d \
  /etc/s6-overlay/s6-rc.d/user/contents.d

# create openwebrx service
echo longrun > /etc/s6-overlay/s6-rc.d/openwebrx/type
cat > /etc/s6-overlay/s6-rc.d/openwebrx/run << _EOF_
#!/command/execlineb -P
/run.sh
_EOF_
chmod +x /etc/s6-overlay/s6-rc.d/openwebrx/run
touch /etc/s6-overlay/s6-rc.d/user/contents.d/openwebrx

# add dependencies
touch /etc/s6-overlay/s6-rc.d/openwebrx/dependencies.d/codecserver
touch /etc/s6-overlay/s6-rc.d/openwebrx/dependencies.d/sdrplay

pwarn "Tiny image..."
rm -f /etc/apt/apt.conf.d/51cache
apt clean
rm -rf /var/lib/apt/lists/*
find / -iname "*.a" -exec rm {} \;
find / -iname "*-old" -exec rm -rf {} \;

pok "Final image done."
