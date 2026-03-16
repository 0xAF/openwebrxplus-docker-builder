#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /common.sh

COMPONENT="radae_decoder"
REPO_URL="https://github.com/peterbmarks/radae_decoder"
REF="main"
SCRIPT_VERSION="1"

if cache_component_should_build "$COMPONENT" "$REPO_URL" "$REF" "$BUILD_CACHE/webrx-rade-decode-minimal_*.deb"; then
  pinfo "Install WebRX Rade Decode Minimal..."
  git_ensure_repo "radae_decoder" "$REPO_URL"
  git_checkout_ref "radae_decoder" "$REF"

  pushd radae_decoder
  arch="$(dpkg --print-architecture)"

  if [ -f cmake/BuildOpus.cmake ]; then
    if ! grep -q 'Add CMake imported target for static Opus' cmake/BuildOpus.cmake; then
      cat <<'EOF' >> cmake/BuildOpus.cmake

# --- Add CMake imported target for static Opus ---
if(NOT TARGET opus)
    add_library(opus STATIC IMPORTED)
    set_target_properties(opus PROPERTIES
        IMPORTED_LOCATION "${CMAKE_BINARY_DIR}/.cache/opus/src/.libs/libopus.a"
        INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_BINARY_DIR}/.cache/opus/src/include"
    )
endif()
EOF
    fi

    sed -i -E 's/(BUILD_COMMAND[[:space:]]+)make$/\1make -j6/' cmake/BuildOpus.cmake
    if [ "${arch}" = "arm64" ]; then
      sed -i 's/\\ -mno-dotprod//g' cmake/BuildOpus.cmake
      sed -i -E 's/CFLAGS=[^ )]+(\\ [^ )]+)*/CFLAGS=-march=armv8-a\\ -O2/' cmake/BuildOpus.cmake
      if ! grep -q -- '--disable-intrinsics' cmake/BuildOpus.cmake; then
        sed -i 's@./configure @./configure --disable-intrinsics @' cmake/BuildOpus.cmake
      fi
    elif [ "${arch}" = "armhf" ]; then
      sed -i 's/CFLAGS=-march=native\\ -O2/CFLAGS=-march=armv7-a+fp\\ -mfloat-abi=hard\\ -O2/' cmake/BuildOpus.cmake
      if ! grep -q -- '--disable-rtcd' cmake/BuildOpus.cmake; then
        sed -i 's@./configure @./configure --disable-rtcd @' cmake/BuildOpus.cmake
      fi
      if ! grep -q -- '--disable-asm' cmake/BuildOpus.cmake; then
        sed -i 's@./configure @./configure --disable-asm @' cmake/BuildOpus.cmake
      fi
      if ! grep -q -- '--disable-intrinsics' cmake/BuildOpus.cmake; then
        sed -i 's@./configure @./configure --disable-intrinsics @' cmake/BuildOpus.cmake
      fi
    fi
  fi

  dpkg-buildpackage -us -uc -j"$(nproc --ignore=4)" -Ppkg.minimal
  popd

  cache_component_record "$COMPONENT" "$REPO_URL" "$REF" "$SCRIPT_VERSION" "$BUILD_CACHE/webrx-rade-decode-minimal_*.deb"
fi
