#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /common.sh

echo;echo;echo;echo;echo;echo;echo
pinfo "Building base image..."
pinfo "MAKEFLAGS: ${MAKEFLAGS:-}"
pinfo "PLATFORM: ${PLATFORM}"

if [ -n "${APT_PROXY:-}" ]; then
  pinfo "Setup APT proxy..."
  export http_proxy=${APT_PROXY}
  cat > /etc/apt/apt.conf.d/51cache << EOF
Acquire::http { Proxy "${APT_PROXY}"; Timeout "30"; Pipeline-Depth "0"; };
Acquire::https { Timeout "30"; };
Acquire::Retries "2";
EOF
fi

cat >> /root/.bashrc << _EOF_
rm -f /etc/apt/apt.conf.d/51cache
if [ -n "\${http_proxy:-}" ]; then echo 'Acquire::http { Proxy "'\${http_proxy:-}'"; };' > /etc/apt/apt.conf.d/51cache; fi

export LS_OPTIONS='--color=auto --group-directories-first -p'
eval "\$(dircolors -b)"
alias ls='ls \$LS_OPTIONS'

export TERM=xterm-color

export ENTER_SHELL=1
source /common.sh

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

VERSION_CODENAME="$(detect_version_codename)"

case "$VERSION_CODENAME" in
  bookworm|trixie)
    pinfo "Enabling Debian non-free repositories for $VERSION_CODENAME..."
    cat > /etc/apt/sources.list.d/debian-nonfree.list << EOF
deb http://deb.debian.org/debian $VERSION_CODENAME main contrib non-free non-free-firmware
deb http://deb.debian.org/debian $VERSION_CODENAME-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security $VERSION_CODENAME-security main contrib non-free non-free-firmware
EOF
    ;;
  *) ;;
esac

case "$VERSION_CODENAME" in
  bookworm)
    pinfo "Detected Debian Bookworm."
    PACKAGES='
      libboost-program-options1.74.0
      libboost-log1.74.0
      libconfig++9v5
      libvolk2.5
      libomp5-14
      libasound2
      libcurl4
      libsqlite3-0
    '
    ;;
  trixie)
    pinfo "Detected Debian Trixie."
    PACKAGES='
      libboost-program-options1.83.0
      libboost-log1.83.0
      libconfig++11
      libvolk3.2
      libomp5-17t64
      libasound2t64
      libcurl4t64
    '
    ;;
  *)
    perror "Unknown or unsupported (Debian) VERSION_CODENAME: $VERSION_CODENAME"
    exit 1
    ;;
esac

pinfo "Update apt and install packages..."
apt_update_with_fallback 120
apt -y install --no-install-recommends \
  wget \
  gpg \
  ca-certificates \
  patch \
  sudo \
  vim-tiny \
  xz-utils \
  libairspyhf1 \
  libiio0 \
  libad9361-0 \
  libpopt0 \
  alsa-utils \
  libhidapi-hidraw0 \
  libhidapi-libusb0 \
  libfftw3-single3 \
  libliquid1 \
  libncurses6 \
  libpulse0 \
  less \
  libjemalloc2 \
  libnng1 \
  libzstd1 \
  python3-paho-mqtt \
  libglfw3 \
  socat \
  usbutils \
  ocl-icd-opencl-dev \
  jq \
  iproute2 \
  util-linux \
  ${PACKAGES}

pinfo "Add repos and update apt again..."
wget -O - https://luarvique.github.io/ppa/openwebrx-plus.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/openwebrx-plus.gpg
echo "deb [signed-by=/etc/apt/trusted.gpg.d/openwebrx-plus.gpg] https://luarvique.github.io/ppa/${VERSION_CODENAME} ./" > /etc/apt/sources.list.d/openwebrx-plus.list

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

apt_update_with_fallback 120
apt upgrade -y

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
patch --verbose -Np0 < "/sdrplay-patch/$SDRPLAY_BINARY.patch"
cd sdrplay
mkdir -p /etc/udev/rules.d
./install_lib.sh
cd ..
rm -rf sdrplay

mkdir -p \
  /etc/s6-overlay/s6-rc.d/sdrplay/dependencies.d \
  /etc/s6-overlay/s6-rc.d/user/contents.d

touch /etc/s6-overlay/s6-rc.d/user/contents.d/sdrplay
echo longrun > /etc/s6-overlay/s6-rc.d/sdrplay/type
cat > /etc/s6-overlay/s6-rc.d/sdrplay/run << _EOF_
#!/command/execlineb -P
/usr/local/bin/sdrplay_apiService
_EOF_
chmod +x /etc/s6-overlay/s6-rc.d/sdrplay/run
ln -sf /opt/sdrplay_api/sdrplay_apiService /usr/local/bin/

popd
rm -rf /sdrplay

pinfo "Install OWRX deps from deb packages..."
apt-install-depends openwebrx
apt install -y soapysdr-module-sdrplay3 soapysdr-module-all acarsdec soapysdr-tools dream hackrf soapysdr-module-hackrf sonde-decoders aprs-symbols

mkdir -p \
  /etc/s6-overlay/s6-rc.d/codecserver/dependencies.d \
  /etc/s6-overlay/s6-rc.d/user/contents.d

touch /etc/s6-overlay/s6-rc.d/user/contents.d/codecserver
echo longrun > /etc/s6-overlay/s6-rc.d/codecserver/type
cat > /etc/s6-overlay/s6-rc.d/codecserver/run << _EOF_
#!/command/execlineb -P
/usr/bin/codecserver
_EOF_
chmod +x /etc/s6-overlay/s6-rc.d/codecserver/run

pwarn "Tiny image..."
SUDO_FORCE_REMOVE=yes apt remove --allow-remove-essential -y --purge --autoremove --ignore-missing \
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
  xz-utils util-linux sensible-utils poppler-data login bsdutils systemd systemd-sysv

apt install tzdata

apt clean
rm -rf /var/lib/apt/lists/* /usr/share/doc/*
find / -iname "*.a" -exec rm {} \;

pok "Base is done."
