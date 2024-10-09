#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /tmp/common.sh

echo;echo;echo;echo;echo;echo;echo
pinfo "Building base image..."
pinfo "MAKEFLAGS: ${MAKEFLAGS:-}"
pinfo "PLATFORM: ${PLATFORM}"


# if we have apt proxy, use it through the build process
# it will be removed for the final image
if [ -n "${APT_PROXY:-}" ]; then
  pinfo "Setup APT proxy..."
  export http_proxy=${APT_PROXY}
  # shellcheck disable=SC2086
  echo 'Acquire::http { Proxy "'${APT_PROXY}'"; };' > /etc/apt/apt.conf.d/51cache
fi

# ease my life
cat >> /root/.bashrc << _EOF_
# remove apt cache, in case it was left from the build
rm -f /etc/apt/apt.conf.d/51cache

# if docker is started with http_proxy env - we will give it to apt
if [ -n "\${http_proxy:-}" ]; then echo 'Acquire::http { Proxy "'\${http_proxy:-}'"; };' > /etc/apt/apt.conf.d/51cache; fi

# why is this not the default?!?
export LS_OPTIONS='--color=auto --group-directories-first -p'
eval "\$(dircolors -b)"
alias ls='ls \$LS_OPTIONS'

# safe default
export TERM=xterm-color

export ENTER_SHELL=1
source /tmp/common.sh

echo;echo;echo;
echo ================================================================
echo "you can use 'owrx-stop' and 'owrx-start' aliases"
echo "s6 info: https://skarnet.org/software/s6-rc/faq.html"
echo ================================================================
echo;echo;echo

alias owrx-stop='s6-rc -d change openwebrx'
alias owrx-start='s6-rc -u change openwebrx'

export PATH=$PATH:/command
_EOF_


pinfo "Update apt and install packages..."
apt update
apt -y install --no-install-recommends wget gpg ca-certificates patch sudo vim-tiny xz-utils libairspyhf1 libiio0 libad9361-0 libpopt0 alsa-utils libhidapi-hidraw0 libhidapi-libusb0 libasound2 libfftw3-single3 libboost-program-options1.74.0 libboost-log1.74.0 libcurl4 libliquid1 libncurses6 libpulse0 libconfig++9v5 less libjemalloc2 libvolk2.5 libnng1 libzstd1 libomp5-14 python3-paho-mqtt libglfw3 socat

pinfo "Add repos and update apt again..."
wget -O - https://luarvique.github.io/ppa/openwebrx-plus.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/openwebrx-plus.gpg
echo "deb [signed-by=/etc/apt/trusted.gpg.d/openwebrx-plus.gpg] https://luarvique.github.io/ppa/bookworm ./" > /etc/apt/sources.list.d/openwebrx-plus.list
# wget -O - https://repo.openwebrx.de/debian/key.gpg.txt | gpg --dearmor -o /usr/share/keyrings/openwebrx.gpg
# echo "deb [signed-by=/usr/share/keyrings/openwebrx.gpg] https://repo.openwebrx.de/debian/ experimental main" > /etc/apt/sources.list.d/openwebrx.list

# if we have a local deb repo in the cache folder
if [ -d /build_cache/deb/ ]; then
  echo "deb [trusted=yes] file:/build_cache/deb ./" > /etc/apt/sources.list.d/local-repo.list
  apt install -y dpkg-dev apt-utils
  mkdir -p /build_cache/deb
  cd deb
  pinfo "Creating local deb repo"
  dpkg-scanpackages --multiversion . /dev/null > Packages
  gzip -k -f Packages
  pinfo "Creating local deb Release"
  apt-ftparchive release . > Release
  cd ..
  apt remove -y --purge --autoremove dpkg-dev apt-utils
fi

apt update
apt upgrade -y



# ---------------------------------------------------------------------
# S6
# ---------------------------------------------------------------------
pinfo "Install S6..."
MD5SUMS='
da1e72e50d3b3d4dc8cf45cfce291a3c  s6-overlay-noarch.tar.xz
79a98f88a3fe2ec760f62635f6807cd9  s6-overlay-x86_64.tar.xz
e95e057958b59dd290385c1698d2dbfe  s6-overlay-aarch64.tar.xz
47d9a8961cd230a035c09f50f1d2050b  s6-overlay-armhf.tar.xz
'
mkdir -p s6
pushd s6
S6_ARCH=$(uname -m)
if [[ $S6_ARCH == "armv7"* ]]; then S6_ARCH="armhf"; fi
if [ -f "s6-overlay-noarch.tar.xz" ] && [ -f "s6-overlay-$S6_ARCH.tar.xz" ] && echo "$MD5SUMS" | md5sum --ignore-missing -c; then
  pinfo "skipping download..."
else
  pinfo "downloading S6"
  rm -f s6-overlay-noarch.tar.xz "s6-overlay-$S6_ARCH.tar.xz"
  wget "https://github.com/just-containers/s6-overlay/releases/download/v3.1.5.0/s6-overlay-noarch.tar.xz"
  wget "https://github.com/just-containers/s6-overlay/releases/download/v3.1.5.0/s6-overlay-$S6_ARCH.tar.xz"
fi
tar -Jxpf "s6-overlay-noarch.tar.xz" -C /
tar -Jxpf "s6-overlay-$S6_ARCH.tar.xz" -C /
popd



# ---------------------------------------------------------------------
# SDRPlay
# INFO: the SDRPLAY_BINARY is comming from common.sh
# ---------------------------------------------------------------------
pinfo "Install SDRPlay..."
MD5SUMS='
1be01c3ae870f09e76f61a0a23e69ccf  SDRplay_RSP_API-ARM32-3.07.2.run
a7281fb46aa35f0d87b13b343c247381  SDRplay_RSP_API-ARM64-3.07.1.run
41fea62ae45d76aaafd6437483386d7f  SDRplay_RSP_API-Linux-3.07.1.run
c739ba0e6c7769957ca79ab05e46f081  SDRplay_RSP_API-Linux-3.14.0.run
b7317257d7498c2fa22d6d53b90f4611  SDRplay_RSP_API-Linux-3.15.1.run
92feae82c39d2e33eec13fc5662a3b9b  SDRplay_RSP_API-Linux-3.15.2.run
'
mkdir -p sdrplay
pushd sdrplay
if [ -f "$SDRPLAY_BINARY" ] && echo "$MD5SUMS" | md5sum --ignore-missing -c; then
  pinfo "skipping download..."
else
  pinfo "downloading $SDRPLAY_BINARY"
  rm -f "$SDRPLAY_BINARY"
  wget --no-http-keep-alive "https://www.sdrplay.com/software/$SDRPLAY_BINARY"
fi
sh "$SDRPLAY_BINARY" --noexec --target sdrplay
patch --verbose -Np0 < "/tmp/sdrplay/$SDRPLAY_BINARY.patch"
cd sdrplay
mkdir -p /etc/udev/rules.d
./install_lib.sh
cd ..
rm -rf sdrplay

mkdir -p \
  /etc/s6-overlay/s6-rc.d/sdrplay/dependencies.d \
  /etc/s6-overlay/s6-rc.d/user/contents.d

# create codecserver service
touch /etc/s6-overlay/s6-rc.d/user/contents.d/sdrplay
echo longrun > /etc/s6-overlay/s6-rc.d/sdrplay/type
cat > /etc/s6-overlay/s6-rc.d/sdrplay/run << _EOF_
#!/command/execlineb -P
/usr/local/bin/sdrplay_apiService
_EOF_
chmod +x /etc/s6-overlay/s6-rc.d/sdrplay/run

# link the binary to its location
ln -sf /opt/sdrplay_api/sdrplay_apiService /usr/local/bin/

popd
rm -rf /tmp/sdrplay


# ---------------------------------------------------------------------
# OWRX+ dependencies
# ---------------------------------------------------------------------
pinfo "Install OWRX deps from deb packages..."
apt-install-depends openwebrx
apt install -y soapysdr-module-sdrplay3 soapysdr-module-all acarsdec soapysdr-tools

mkdir -p \
  /etc/s6-overlay/s6-rc.d/codecserver/dependencies.d \
  /etc/s6-overlay/s6-rc.d/user/contents.d

# create codecserver service
touch /etc/s6-overlay/s6-rc.d/user/contents.d/codecserver
echo longrun > /etc/s6-overlay/s6-rc.d/codecserver/type
cat > /etc/s6-overlay/s6-rc.d/codecserver/run << _EOF_
#!/command/execlineb -P
/usr/bin/codecserver
_EOF_
chmod +x /etc/s6-overlay/s6-rc.d/codecserver/run


pwarn "Tiny image..."
SUDO_FORCE_REMOVE=yes apt remove --allow-remove-essential -y --purge --autoremove \
  dmsetup adwaita-icon-theme ghostscript \
  gsfonts gstreamer1.0-gl \
  patch qttranslations5-l10n \
  libxrandr2 libxinerama1 libxdamage1 libxcursor1 \
  libcolord2 libatk-bridge2.0-0 libepoxy0 libgraphene-1.0-0 libgs10 \
  fonts-font-awesome fonts-noto-mono fonts-open-sans fonts-urw-base35 fonts-droid-fallback \
  dbus dbus-bin dbus-daemon dbus-session-bus-common dbus-system-bus-common \
  gnupg gpg gstreamer1.0-plugins-base gtk-update-icon-cache manpages mount \
  qtwayland5 sudo e2fsprogs libapparmor1 libargon2-1 libatk1.0-0 libatspi2.0-0 \
  libcairo-gobject2 libfdisk1 netpbm tzdata ucf xdg-user-dirs xfonts-utils xfonts-encodings \
  xz-utils util-linux sensible-utils poppler-data login bsdutils

apt install tzdata

apt clean
rm -rf /var/lib/apt/lists/* /usr/share/doc/*
find / -iname "*.a" -exec rm {} \;

pok "Base is done."
