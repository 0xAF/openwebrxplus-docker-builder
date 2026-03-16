#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /common.sh

SCRIPT_VERSION="1"
COMPONENT="msk144decoder"
REPO_URL="https://github.com/alexander-sholohov/msk144decoder.git"
REF="761d0b3a61cde664d4c25b1c6ff1d9c0e395af23"

if cache_component_should_build "$COMPONENT" "$REPO_URL" "$REF" "$BUILD_ROOTFS/usr/local/bin/msk144decoder"; then
  pinfo "Install MSK144..."
  git_ensure_repo "msk144decoder" "$REPO_URL"
  git_checkout_ref "msk144decoder" "$REF"
  MAKEFLAGS="" cmakebuild msk144decoder "$REF"
  cache_component_record "$COMPONENT" "$REPO_URL" "$REF" "$SCRIPT_VERSION" "$BUILD_ROOTFS/usr/local/bin/msk144decoder"
fi
