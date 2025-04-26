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
git clone https://github.com/0xAF/mbelib
cd mbelib
dpkg-buildpackage
cd ..
dpkg -i libmbe1_1.3*.deb libmbe-dev_1.3*.deb

echo "+ Build codecserver-softmbe..."
git clone https://github.com/0xAF/codecserver-softmbe
cd codecserver-softmbe
dpkg-buildpackage
cd ..

mkdir /deb
mv *.deb /deb/
cd /deb
# apt download libcodecserver
ls -la /deb
