#!/bin/bash

# export TERM=${TERM:-xterm}
: ${TERM:=xterm-color}
export TERM

function perror() { printf "\e[7;38;5;1m[+] %-85s\e[0m\n" "$*"; }
function pok() { printf "\e[7;38;5;2m[+] %-85s\e[0m\n" "$*"; }
function pwarn() { printf "\e[7;38;5;3m[+] %-85s\e[0m\n" "$*"; }
function pinfo() { printf "\e[7;38;5;12m[+] %-85s\e[0m\n" "$*"; }

export MARCH=native
case `uname -m` in
  arm*)
    PLATFORM=armhf
    SDRPLAY_BINARY=SDRplay_RSP_API-Linux-3.15.2.run
    ;;
  aarch64*)
    PLATFORM=aarch64
    SDRPLAY_BINARY=SDRplay_RSP_API-Linux-3.15.2.run
    ;;
  x86_64*)
    PLATFORM=amd64
    SDRPLAY_BINARY=SDRplay_RSP_API-Linux-3.15.2.run
    export MARCH=x86-64
    ;;
  *)
    echo "Unknown platform (`uname -m`) to build."
    exit 1
    ;;
esac

if [ -z "${ENTER_SHELL:-}" ]; then
  if [ ! -d /build_cache ]; then
    echo;echo;echo;
    perror "ERROR: This build must have a volume mounted in /build_cache"
    echo;echo;echo
    exit 1
  fi

  export BUILD_CACHE=/build_cache/`uname -m`
  export BUILD_ROOTFS=/build_cache/`uname -m`/rootfs
  mkdir -p $BUILD_CACHE $BUILD_ROOTFS
  cd $BUILD_CACHE
fi

function cmakebuild() {
  cd $1
  if [[ ! -z "${2:-}" ]]; then
    git checkout $2
  fi
  if [[ -f ".gitmodules" ]]; then
    git submodule update --init
  fi
  rm -rf build
  mkdir build
  cd build
  cmake ${CMAKE_ARGS:-} ..
  make
  make install DESTDIR=$BUILD_ROOTFS/
  make install # in case other compilations need this one, make it available in the build image too
  ldconfig
  cd ../..
}

function apt-install-depends() {
    local pkg="$1"
    apt install -s "$pkg" \
      | sed -n \
        -e "/^Inst $pkg /d" \
        -e 's/^Inst \([^ ]\+\) .*$/\1/p' \
      | xargs apt install
}

alias systemctl=true

