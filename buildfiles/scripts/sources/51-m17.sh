#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /common.sh

SCRIPT_VERSION="1"
COMPONENT="m17-demod"
REPO_URL="https://github.com/mobilinkd/m17-cxx-demod.git"
REF="master"

if cache_component_should_build "$COMPONENT" "$REPO_URL" "$REF" "$BUILD_ROOTFS/usr/local/bin/m17-demod"; then
  pinfo "Install M17..."
  git_ensure_repo "m17-cxx-demod" "$REPO_URL"
  git_checkout_ref "m17-cxx-demod" "$REF"
  git -C m17-cxx-demod submodule update --init --recursive
  cmakebuild m17-cxx-demod
  cache_component_record "$COMPONENT" "$REPO_URL" "$REF" "$SCRIPT_VERSION" "$BUILD_ROOTFS/usr/local/bin/m17-demod"
fi
