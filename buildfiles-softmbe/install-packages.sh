#!/bin/bash
set -euxo pipefail

dpkg -i /deb/libmbe1_1.3.0_*.deb


echo "+ Install codecserver-softmbe..."
#dpkg -i /deb/libcodecserver_*.deb
dpkg -i /deb/codecserver-driver-softmbe_0.0.1_*.deb
rm -rf /deb

# add the softmbe library to the codecserver config
#linklib=$(dpkg -L codecserver-driver-softmbe | grep libsoftmbe.so)
#ln -s $linklib /usr/local/lib/codecserver/
cat >> /etc/codecserver/codecserver.conf << _EOF_

# add softmbe
[device:softmbe]
driver=softmbe
_EOF_

#sed -i 's/set -euo pipefail/set -euo pipefail\ncd \/opt\/openwebrx/' /opt/openwebrx/docker/scripts/run.sh
#sed -i 's/set -euo pipefail/set -euo pipefail\ncd \/opt\/openwebrx/' /run.sh
