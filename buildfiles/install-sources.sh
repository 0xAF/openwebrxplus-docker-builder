#!/bin/bash
set -euo pipefail

source /tmp/common.sh

export PATH=/usr/local/go/bin:$PATH
mkdir -p /go
mkdir -p /gocache
export GOPATH=/go
export GOCACHE=/gocache

echo;echo;echo;echo;echo;echo;echo
pinfo "Building from sources..."
pinfo "MAKEFLAGS: ${MAKEFLAGS:-}"
pinfo "PLATFORM: ${PLATFORM}"

echo ${BUILD_DATE:-unknown} > /build-sources-date

pinfo "Install dev packages..."
BUILD_PACKAGES="git cmake make patch wget sudo libusb-1.0-0-dev libsoapysdr-dev debhelper build-essential pkg-config libairspyhf-dev dpkg-dev xxd libpopt-dev libiio-dev libad9361-dev libhidapi-dev libasound2-dev libfftw3-dev libowrx-connector-dev libboost-dev libboost-program-options-dev libboost-log-dev libboost-regex-dev gfortran libcurl4-openssl-dev qt5-qmake libpulse-dev libncurses-dev libliquid-dev libconfig++-dev libpng-dev libtiff-dev libjemalloc-dev libvolk2-dev libnng-dev libzstd-dev libomp-dev ocl-icd-opencl-dev libglfw3-dev"
apt update
apt install -y --no-install-recommends $BUILD_PACKAGES

mkdir -p $BUILD_ROOTFS/usr/local/bin

# has deb
if ! ls soapysdr0.8-module-airspyhf*.deb 1>/dev/null 2>&1; then
  pinfo "Install AirSpyHF..."
  if [ -d "SoapyAirspyHF" ]; then
    cd SoapyAirspyHF
    git checkout .
    git checkout master
    git pull
    cd ..
  else
    git clone https://github.com/pothosware/SoapyAirspyHF.git
  fi
  # cmakebuild SoapyAirspyHF 5488dac5b44f1432ce67b40b915f7e61d3bd4853
  # cmakebuild SoapyAirspyHF
  cd SoapyAirspyHF
  patch -p1 < /files/airspy/version.patch
  dpkg-buildpackage -b
  cd ..
else
  pinfo "AirSpyHF already built..."
fi

# no deb
if ! [ -f $BUILD_ROOTFS/usr/local/bin/perseustest ]; then
  pinfo "Install PerseusSDR..."
  if [ -d "libperseus-sdr" ]; then
    cd libperseus-sdr
    git pull
    cd ..
  else
    git clone https://github.com/Microtelecom/libperseus-sdr.git
  fi

  cd libperseus-sdr
  ./bootstrap.sh
  ./configure
  make
  make install DESTDIR=$BUILD_ROOTFS/
  cd ..
else
  pinfo "PerseusSDR already built..."
fi


# no deb
if ! [ -f $BUILD_ROOTFS/usr/local/bin/rockprog ]; then
  pinfo "Install RockProg..."
  if [ -d "rockprog-linux" ]; then
    cd rockprog-linux
    git pull
    cd ..
  else
    git clone https://github.com/0xAF/rockprog-linux
  fi

  cd rockprog-linux
  make
  install -D rockprog $BUILD_ROOTFS/usr/local/bin/
  cd ..
else
  pinfo "RockProg already built..."
fi


# has deb
if ! ls soapysdr0.8-module-plutosdr_*.deb 1>/dev/null 2>&1; then
  pinfo "Install PlutoSDR..."
  if [ -d "SoapyPlutoSDR" ]; then
    cd SoapyPlutoSDR
    git checkout .
    git checkout master
    git pull
    cd ..
  else
    git clone https://github.com/pothosware/SoapyPlutoSDR.git
  fi
  # cmakebuild SoapyPlutoSDR 93717b32ef052e0dfa717aa2c1a4eb27af16111f
  cd SoapyPlutoSDR
  patch -p1 < /files/plutosdr/version.patch
  dpkg-buildpackage -b
  cd ..
else
  pinfo "PlutoSDR already built..."
fi


# no deb
if ! [ -f $BUILD_ROOTFS/usr/local/lib/SoapySDR/modules*/libSoapyRadioberrySDR.so ]; then
  pinfo "Install RaddioberrySDR..."
  if [ -d "Radioberry-2.x" ]; then
    cd Radioberry-2.x
    git pull
    cd ..
  else
    git clone https://github.com/pa3gsb/Radioberry-2.x
  fi

  cd Radioberry-2.x/SBC/rpi-4
  # cmakebuild SoapyRadioberrySDR 8d17de6b4dc076e628900a82f05c7cf0b16cbe24
  cmakebuild SoapyRadioberrySDR
  cd ../../../
else
  pinfo "RadioberrySDR already built..."
fi


# TODO: has deb
if ! [ -f $BUILD_ROOTFS/usr/local/lib/SoapySDR/modules*/libFCDPPSupport.so ]; then
  pinfo "Install FCDPP..."
  if [ -d "SoapyFCDPP" ]; then
    cd SoapyFCDPP
    git checkout master
    git pull
    cd ..
  else
    git clone https://github.com/pothosware/SoapyFCDPP.git
  fi

  cmakebuild SoapyFCDPP soapy-fcdpp-0.1.1
else
  pinfo "FCDPP already built..."
fi


# no deb
#if ! [ -f $BUILD_ROOTFS/usr/local/bin/hpsdrconnector ]; then
#  pinfo "Install HPSDR..."
#  if [ -d "hpsdrconnector" ]; then
#    cd hpsdrconnector
#    git checkout master
#    git pull
#    cd ..
#  else
#    git clone https://github.com/jancona/hpsdrconnector.git
#  fi
#
#  cd hpsdrconnector
#  git checkout v0.6.1
#  go build
#  install -D -m 0755 hpsdrconnector $BUILD_ROOTFS/usr/local/bin/
#  cd ..
#else
#  pinfo "HPSDR already built..."
#fi


# TODO: has deb
if ! ls runds-connector_*.deb 1>/dev/null 2>&1; then
  pinfo "Install RUNDS..."
  if [ -d "runds_connector" ]; then
    cd runds_connector
    git checkout master
    git pull
    cd ..
  else
    git clone https://github.com/jketterl/runds_connector
  fi

  # cmakebuild runds_connector master
  cd runds_connector
  # git checkout 435364002d756735015707e7f59aa40e8d743585
  git checkout 06ca993a3c81ddb0a2581b1474895da07752a9e1
  dpkg-buildpackage -b
  cd ..
else
  pinfo "RUNDS already built..."
fi


# no deb
if ! [ -f $BUILD_ROOTFS/usr/local/bin/freedv_rx ]; then
  pinfo "Install FreeDV..."
  if [ -d "codec2" ]; then
    cd codec2
    git checkout .
    git checkout main
    git pull
    cd ..
  else
    git clone https://github.com/drowe67/codec2.git
  fi

  cd codec2
  git checkout 1.2.0
  mkdir -p build
  cd build
  cmake ..
  make
  make install DESTDIR=$BUILD_ROOTFS/
  install -D -m 0755 src/freedv_rx $BUILD_ROOTFS/usr/local/bin
  cd ../..
else
  pinfo "FreeDV already built..."
fi
cp -a $BUILD_ROOTFS/usr/local/include/* /usr/local/include/
cp -a $BUILD_ROOTFS/usr/local/lib/* /usr/local/lib/



# no deb
if ! [ -f $BUILD_ROOTFS/usr/local/bin/m17-demod ]; then
  pinfo "Install M17..."
  if [ -d "m17-cxx-demod" ]; then
    cd m17-cxx-demod
    git checkout .
    git checkout master
    git pull
    cd ..
  else
    git clone https://github.com/mobilinkd/m17-cxx-demod.git
  fi

  cmakebuild m17-cxx-demod v2.3
else
  pinfo "M17 already built..."
fi


# no deb
if ! [ -f $BUILD_ROOTFS/usr/local/bin/msk144decoder ]; then
  pinfo "Install MSK144..."
  if [ -d "msk144decoder" ]; then
    cd msk144decoder
    git checkout .
    git checkout master
    git pull
    cd ..
  else
    git clone https://github.com/alexander-sholohov/msk144decoder.git
  fi

  MAKEFLAGS="" cmakebuild msk144decoder fe2991681e455636e258e83c29fd4b2a72d16095
else
  pinfo "MSK144 already built..."
fi


# no deb
if ! [ -f $BUILD_ROOTFS/usr/local/bin/dream ]; then
  pinfo "Install DRM..."
  if ! [ -d "dream" ]; then
    rm -f dream-2.1.1-svn808.tar.gz
    wget https://downloads.sourceforge.net/project/drm/dream/2.1.1/dream-2.1.1-svn808.tar.gz
    tar xvfz dream-2.1.1-svn808.tar.gz
    cd dream
    patch -Np0 < /files/dream/dream.patch
    cd ..
  fi

  cd dream
  qmake CONFIG+=console
  make
  install -D -m 0755 dream $BUILD_ROOTFS/usr/local/bin/
  cd ..
else
  pinfo "DRM already built..."
fi


# TODO: has deb
#if ! [ -f $BUILD_ROOTFS/usr/local/bin/dump1090 ]; then
#  pinfo "Install Dump1090..."
#  if [ -d "dump1090" ]; then
#    cd dump1090
#    git checkout .
#    git pull
#    cd ..
#  else
#    git clone --depth 1 -b v8.2 https://github.com/flightaware/dump1090
#  fi
#
#  cd dump1090
#  make
#  install -D -m 0755 dump1090 $BUILD_ROOTFS/usr/local/bin/
#  cd ..
#else
#  pinfo "Dump1090 already built..."
#fi

# no deb
#if ! [ -f $BUILD_ROOTFS/usr/local/lib/libacars-2.so ]; then
#  pinfo "Install LibACARS..."
#  if [ -d "libacars" ]; then
#    cd libacars
#    git checkout .
#    git checkout master
#    git pull
#    cd ..
#  else
#    git clone https://github.com/szpajder/libacars.git
#  fi
#
#  cmakebuild libacars v2.2.0
#else
#  pinfo "LibACARS already built..."
#fi
#mkdir -p /usr/local/lib/pkgconfig/ /usr/local/include/
#cp -a $BUILD_ROOTFS/usr/local/include/libacars* /usr/local/include/
#cp -a $BUILD_ROOTFS/usr/local/lib/libacars* /usr/local/lib/
#cp -a $BUILD_ROOTFS/usr/local/lib/pkgconfig/libacars*.pc /usr/local/lib/pkgconfig/


# no deb
#if ! [ -f $BUILD_ROOTFS/usr/local/bin/acarsdec ]; then
#  pinfo "Install ACARSdec..."
#  if [ -d "acarsdec" ]; then
#    cd acarsdec
#    git checkout .
#    git checkout master
#    git pull
#    cd ..
#  else
#    git clone https://github.com/TLeconte/acarsdec.git
#  fi
#
#  sed -i 's/-march=native/-march='${MARCH}'/g' acarsdec/CMakeLists.txt
#  cmakebuild acarsdec
#else
#  pinfo "ACARSdec already built..."
#fi


# no deb
#if ! [ -f $BUILD_ROOTFS/usr/local/bin/dumphfdl ]; then
#  pinfo "Install DumpHFDL..."
#  if [ -d "dumphfdl" ]; then
#    cd dumphfdl
#    git checkout .
#    git checkout master
#    git pull
#    cd ..
#  else
#    git clone https://github.com/szpajder/dumphfdl.git
#  fi
#
#  cmakebuild dumphfdl v1.4.1
#else
#  pinfo "DumpHFDL already built..."
#fi


# no deb
#if ! [ -f $BUILD_ROOTFS/usr/local/bin/dumpvdl2 ]; then
#  pinfo "Install DumpVDL2..."
#  if [ -d "dumpvdl2" ]; then
#    cd dumpvdl2
#    git checkout .
#    git checkout master
#    git pull
#    cd ..
#  else
#    git clone https://github.com/szpajder/dumpvdl2.git
#  fi
#
#  cmakebuild dumpvdl2 v2.3.0
#else
#  pinfo "DumpVDL2 already built..."
#fi


# no deb
if ! [ -f $BUILD_ROOTFS/usr/local/lib/SoapySDR/modules*/libafedriDevice.so ]; then
  pinfo "Install SoapyAfedri..."
  if [ -d "SoapyAfedri" ]; then
    cd SoapyAfedri
    git checkout .
    git checkout master
    git pull
    cd ..
  else
    git clone https://github.com/alexander-sholohov/SoapyAfedri.git
  fi

  cmakebuild SoapyAfedri
else
  pinfo "SoapyAfedri built..."
fi


# no deb
if ! [ -f $BUILD_ROOTFS/usr/bin/satdump ]; then
  pinfo "Install satdump..."
  if [ -d "satdump" ]; then
    cd satdump
    git checkout .
    git checkout master
    git pull
    cd ..
  else
    git clone https://github.com/altillimity/satdump.git
  fi

  CMAKE_ARGS="-DBUILD_GUI=OFF" cmakebuild satdump
else
  pinfo "satdump built..."
fi



# no deb
if ! [ -d $BUILD_ROOTFS/usr/share/aprs-symbols ]; then
  pinfo "Install APRS Symbols..."
  git clone https://github.com/hessu/aprs-symbols $BUILD_ROOTFS/usr/share/aprs-symbols
  pushd $BUILD_ROOTFS/usr/share/aprs-symbols
  git checkout 5c2abe2658ee4d2563f3c73b90c6f59124839802
  # remove unused files (including git meta information)
  rm -rf .git aprs-symbols.ai aprs-sym-export.js
  popd
else
  pinfo "APRS Symbols already installed..."
fi


rm -f $BUILD_CACHE/*.buildinfo
rm -f $BUILD_CACHE/*.changes

pok "Sources done."
