#!/bin/bash
set -euxo pipefail

echo "+ init..."
apt update
apt-get -y install --no-install-recommends wget gpg ca-certificates

echo "+ Add repos and update..."
wget -O - https://luarvique.github.io/ppa/openwebrx-plus.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/openwebrx-plus.gpg
echo "deb [signed-by=/etc/apt/trusted.gpg.d/openwebrx-plus.gpg] https://luarvique.github.io/ppa/bookworm ./" > /etc/apt/sources.list.d/openwebrx-plus.list
apt update
apt upgrade -y

echo "+ Install dev packages..."
BUILD_PACKAGES="git build-essential debhelper cmake libprotobuf-dev protobuf-compiler libcodecserver-dev wget gpg"
apt-get -y install --no-install-recommends $BUILD_PACKAGES

echo "+ Build MBELIB..."
git clone https://github.com/szechyjs/mbelib.git
cd mbelib
dpkg-buildpackage
cd ..
dpkg -i libmbe1_1.3.0_*.deb libmbe-dev_1.3.0_*.deb

echo "+ Build codecserver-softmbe..."
git clone https://github.com/knatterfunker/codecserver-softmbe.git
cd codecserver-softmbe
# ignore missing library linking error in dpkg-buildpackage command
sed -i 's/dh \$@/dh \$@ --dpkg-shlibdeps-params=--ignore-missing-info/' debian/rules
dpkg-buildpackage
cd ..

mkdir /deb
mv *.deb /deb/
cd /deb
# apt download libcodecserver
ls -la /deb
