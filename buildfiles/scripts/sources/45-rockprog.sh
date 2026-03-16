#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /common.sh

SCRIPT_VERSION="1"
COMPONENT="rockprog"
REPO_URL="https://github.com/0xAF/rockprog-linux"
REF="main"

if cache_component_should_build "$COMPONENT" "$REPO_URL" "$REF" "$BUILD_ROOTFS/usr/local/bin/rockprog"; then
  pinfo "Install RockProg..."
  git_ensure_repo "rockprog-linux" "$REPO_URL"
  git_checkout_ref "rockprog-linux" "$REF"
  pushd rockprog-linux
  make
  install -D rockprog "$BUILD_ROOTFS"/usr/local/bin/
  popd
  cache_component_record "$COMPONENT" "$REPO_URL" "$REF" "$SCRIPT_VERSION" "$BUILD_ROOTFS/usr/local/bin/rockprog"
fi
