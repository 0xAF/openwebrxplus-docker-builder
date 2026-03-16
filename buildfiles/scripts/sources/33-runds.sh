#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /common.sh

SCRIPT_VERSION="1"
COMPONENT="runds-connector"
REPO_URL="https://github.com/jketterl/runds_connector"
REF="06ca993a3c81ddb0a2581b1474895da07752a9e1"

if cache_component_should_build "$COMPONENT" "$REPO_URL" "$REF" "$BUILD_CACHE/runds-connector_*.deb"; then
  pinfo "Install RUNDS..."
  git_ensure_repo "runds_connector" "$REPO_URL"
  git_checkout_ref "runds_connector" "$REF"
  pushd runds_connector
  dpkg-buildpackage -b
  popd
  cache_component_record "$COMPONENT" "$REPO_URL" "$REF" "$SCRIPT_VERSION" "$BUILD_CACHE/runds-connector_*.deb"
fi
