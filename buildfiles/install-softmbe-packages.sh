#!/bin/bash
set -euxo pipefail

MBELIB_VARIANT="$(cat /deb/mbelib-variant)"
install -m 0644 /deb/mbelib-variant /build-mbelib-variant

case "$MBELIB_VARIANT" in
	legacy)
		echo "+ Install legacy libmbe..."
		dpkg -i /deb/libmbe1_1.3*.deb
		ADAPTER_PACKAGES=(/deb/codecserver-driver-softmbe_0.0.1_*.deb)
		;;
	neo-v2)
		echo "+ Install mbelib-neo v2..."
		dpkg -i /deb/libmbe-neo2_2.0.0_*.deb
		ADAPTER_PACKAGES=(/deb/codecserver-driver-softmbe-neo_0.0.2_*.deb)
		;;
	*)
		echo "Unknown mbelib variant: $MBELIB_VARIANT" >&2
		exit 2
		;;
esac

echo "+ Install codecserver-softmbe driver..."
dpkg -i "${ADAPTER_PACKAGES[@]}"

rm -rf /deb

# add the softmbe library to the codecserver config
#linklib=$(dpkg -L codecserver-driver-softmbe | grep libsoftmbe.so)
#ln -s $linklib /usr/local/lib/codecserver/

echo "+ Configuring codecserver..."
cat >> /etc/codecserver/codecserver.conf << _EOF_

# add softmbe
[device:softmbe]
driver=softmbe
_EOF_

#sed -i 's/set -euo pipefail/set -euo pipefail\ncd \/opt\/openwebrx/' /opt/openwebrx/docker/scripts/run.sh
#sed -i 's/set -euo pipefail/set -euo pipefail\ncd \/opt\/openwebrx/' /run.sh
