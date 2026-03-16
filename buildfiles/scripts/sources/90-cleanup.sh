#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /common.sh

rm -f "$BUILD_CACHE"/*.buildinfo
rm -f "$BUILD_CACHE"/*.changes

pok "Sources done."
