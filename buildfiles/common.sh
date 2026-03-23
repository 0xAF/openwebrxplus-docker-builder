#!/bin/bash

# export TERM=${TERM:-xterm}
: ${TERM:=xterm-color}
export TERM

if [ -z "${ENTER_SHELL:-}" ]; then
  set -euo pipefail
fi

function perror() { printf "\e[38;5;15;48;5;1m[+] %-85s\e[0m\n" "$*"; }
function pok() { printf "\e[38;5;15;48;5;34m[+] %-85s\e[0m\n" "$*"; }
function pwarn() { printf "\e[38;5;15;48;5;3m[+] %-85s\e[0m\n" "$*"; }
function pinfo() { printf "\e[38;5;15;48;5;12m[+] %-85s\e[0m\n" "$*"; }

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

if [ -d /build_cache ]; then
  export BUILD_CACHE="${BUILD_CACHE:-/build_cache/`uname -m`}"
  export BUILD_ROOTFS="${BUILD_ROOTFS:-${BUILD_CACHE}/rootfs}"
  mkdir -p "$BUILD_CACHE" "$BUILD_ROOTFS"
  if [ -z "${ENTER_SHELL:-}" ]; then
    cd "$BUILD_CACHE"
  fi
elif [ -z "${ENTER_SHELL:-}" ]; then
  echo;echo;echo;
  perror "ERROR: This build must have a volume mounted in /build_cache"
  echo;echo;echo
  exit 1
fi

function cmakebuild() {
  cd $1
  if [[ ! -z "${2:-}" ]]; then
    pinfo "Checking out git branch/tag/commit $2"
    git checkout $2
  fi
  if [[ -f ".gitmodules" ]]; then
    pinfo "Updating git submodules"
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

apt_update_with_fallback() {
  local timeout_sec="${1:-600}"

  if timeout "${timeout_sec}" apt update; then
    return 0
  fi

  pwarn "apt update failed or timed out (${timeout_sec}s)."

  # If the apt proxy config is present, disable it and retry once directly.
  if [ -f /etc/apt/apt.conf.d/51cache ]; then
    pwarn "Disabling apt proxy config and retrying apt update directly..."
    mv /etc/apt/apt.conf.d/51cache /etc/apt/apt.conf.d/51cache.disabled || true
  fi

  unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY

  timeout "${timeout_sec}" apt update
}

alias systemctl=true

run_numbered_scripts() {
  local script_dir="$1"
  local script

  if [ ! -d "$script_dir" ]; then
    perror "Script directory not found: $script_dir"
    exit 1
  fi

  for script in "$script_dir"/*.sh; do
    if [ ! -f "$script" ]; then
      continue
    fi
    pinfo "Running $(basename "$script")"
    bash "$script"
  done
}

detect_version_codename() {
  grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '"'
}

init_sources_cache() {
  : "${VERSION_CODENAME:=$(detect_version_codename)}"
  export SOURCES_CACHE_ROOT="/build_cache/sources/${PLATFORM}/${VERSION_CODENAME}"
  mkdir -p "$SOURCES_CACHE_ROOT"
}

cache_component_dir() {
  local component="$1"
  init_sources_cache
  echo "$SOURCES_CACHE_ROOT/$component"
}

cache_component_metadata() {
  local component="$1"
  echo "$(cache_component_dir "$component")/metadata.json"
}

cache_component_snapshot_dir() {
  local component="$1"
  echo "$(cache_component_dir "$component")/snapshot"
}

resolve_remote_commit() {
  local repo_url="$1"
  local ref="$2"
  local sha=""

  if [[ "$ref" =~ ^[0-9a-fA-F]{7,40}$ ]]; then
    echo "$ref"
    return 0
  fi

  sha=$(git ls-remote "$repo_url" "$ref" "refs/heads/$ref" "refs/tags/$ref" 2>/dev/null | awk 'NR==1 { print $1 }')
  if [ -z "$sha" ]; then
    sha="$ref"
  fi

  echo "$sha"
}

cache_pattern_exists() {
  local pattern="$1"
  compgen -G "$pattern" >/dev/null
}

cache_restore_component() {
  local component="$1"
  local snapshot_dir
  snapshot_dir="$(cache_component_snapshot_dir "$component")"

  if [ -d "$snapshot_dir" ] && [ -n "$(find "$snapshot_dir" -mindepth 1 -print -quit 2>/dev/null)" ]; then
    pinfo "Restoring cached artifacts for $component"
    cp -a "$snapshot_dir"/. /
  fi
}

cache_component_should_build() {
  local component="$1"
  local repo_url="$2"
  local ref="$3"
  shift 3
  local patterns=("$@")
  local metadata_file
  local previous_commit=""
  local remote_commit=""
  local missing_artifacts=0
  local pattern

  metadata_file="$(cache_component_metadata "$component")"
  remote_commit="$(resolve_remote_commit "$repo_url" "$ref")"
  export CACHE_COMPONENT_REMOTE_COMMIT="$remote_commit"

  if [ "${FORCE_REBUILD:-0}" = "1" ]; then
    pwarn "FORCE_REBUILD=1 set, rebuilding $component"
    return 0
  fi

  if [ -f "$metadata_file" ]; then
    previous_commit=$(jq -r '.resolved_commit // ""' "$metadata_file" 2>/dev/null || true)
  fi

  for pattern in "${patterns[@]}"; do
    if ! cache_pattern_exists "$pattern"; then
      missing_artifacts=1
      break
    fi
  done

  if [ "$missing_artifacts" -eq 1 ]; then
    cache_restore_component "$component"
    missing_artifacts=0
    for pattern in "${patterns[@]}"; do
      if ! cache_pattern_exists "$pattern"; then
        missing_artifacts=1
        break
      fi
    done
  fi

  if [ ! -f "$metadata_file" ]; then
    pinfo "CACHE MISS $component (no metadata)"
    return 0
  fi

  if [ "$previous_commit" != "$remote_commit" ]; then
    pinfo "UPSTREAM CHANGED $component ($previous_commit -> $remote_commit)"
    return 0
  fi

  if [ "$missing_artifacts" -eq 1 ]; then
    pinfo "CACHE MISS $component (artifacts missing)"
    return 0
  fi

  pinfo "CACHE HIT $component ($remote_commit)"
  return 1
}

cache_component_record() {
  local component="$1"
  local repo_url="$2"
  local ref="$3"
  local script_version="$4"
  shift 4
  local patterns=("$@")
  local component_dir
  local metadata_file
  local snapshot_dir
  local tmp_metadata_file
  local resolved_commit
  local pattern
  local path
  local artifact_list_json="[]"
  local artifact_paths=()

  component_dir="$(cache_component_dir "$component")"
  metadata_file="$(cache_component_metadata "$component")"
  snapshot_dir="$(cache_component_snapshot_dir "$component")"
  resolved_commit="${CACHE_COMPONENT_REMOTE_COMMIT:-$(resolve_remote_commit "$repo_url" "$ref")}" 

  mkdir -p "$component_dir"
  rm -rf "$snapshot_dir"
  mkdir -p "$snapshot_dir"

  for pattern in "${patterns[@]}"; do
    while IFS= read -r path; do
      [ -e "$path" ] || continue
      mkdir -p "$snapshot_dir$(dirname "$path")"
      cp -a "$path" "$snapshot_dir$path"
      artifact_paths+=("$path")
    done < <(compgen -G "$pattern" || true)
  done

  if [ "${#artifact_paths[@]}" -gt 0 ]; then
    artifact_list_json=$(printf '%s\n' "${artifact_paths[@]}" | jq -R . | jq -s .)
  fi

  tmp_metadata_file="${metadata_file}.tmp"
  jq -n \
    --arg repo "$repo_url" \
    --arg ref "$ref" \
    --arg commit "$resolved_commit" \
    --arg script_version "$script_version" \
    --arg last_built_at "$(date -u +%FT%TZ)" \
    --argjson artifacts "$artifact_list_json" \
    '{repo:$repo, ref:$ref, resolved_commit:$commit, build_script_version:$script_version, artifact_globs:$artifacts, last_built_at:$last_built_at}' > "$tmp_metadata_file"
  mv "$tmp_metadata_file" "$metadata_file"
}

git_ensure_repo() {
  local repo_dir="$1"
  local repo_url="$2"

  if [ -d "$repo_dir/.git" ]; then
    git -C "$repo_dir" remote set-url origin "$repo_url"
    git -C "$repo_dir" fetch --tags --prune origin
  else
    git clone "$repo_url" "$repo_dir"
  fi
}

git_checkout_ref() {
  local repo_dir="$1"
  local ref="$2"
  local default_remote_ref=""
  local alt_ref=""

  git -C "$repo_dir" checkout .
  git -C "$repo_dir" clean -fd
  git -C "$repo_dir" fetch --tags --prune origin

  default_remote_ref=$(git -C "$repo_dir" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)

  if [ "$ref" = "HEAD" ]; then
    if [ -n "$default_remote_ref" ]; then
      if git -C "$repo_dir" checkout -B "${default_remote_ref#origin/}" "$default_remote_ref" 2>/dev/null; then
        return 0
      fi
      if git -C "$repo_dir" checkout --detach "$default_remote_ref" 2>/dev/null; then
        return 0
      fi
    fi
    return 0
  fi

  if git -C "$repo_dir" checkout "$ref" 2>/dev/null; then
    return 0
  fi

  if git -C "$repo_dir" show-ref --verify --quiet "refs/remotes/origin/$ref" && git -C "$repo_dir" checkout -B "$ref" "origin/$ref" 2>/dev/null; then
    return 0
  fi

  if git -C "$repo_dir" show-ref --verify --quiet "refs/tags/$ref" && git -C "$repo_dir" checkout "tags/$ref" 2>/dev/null; then
    return 0
  fi

  if [[ "$ref" =~ ^[0-9a-fA-F]{7,40}$ ]] && git -C "$repo_dir" checkout --detach "$ref" 2>/dev/null; then
    return 0
  fi

  if [ "$ref" = "main" ]; then
    alt_ref="master"
  elif [ "$ref" = "master" ]; then
    alt_ref="main"
  fi

  if [ -n "$alt_ref" ]; then
    if git -C "$repo_dir" checkout "$alt_ref" 2>/dev/null; then
      return 0
    fi
    if git -C "$repo_dir" show-ref --verify --quiet "refs/remotes/origin/$alt_ref" && git -C "$repo_dir" checkout -B "$alt_ref" "origin/$alt_ref" 2>/dev/null; then
      return 0
    fi
  fi

  if [ -n "$default_remote_ref" ]; then
    if git -C "$repo_dir" checkout -B "${default_remote_ref#origin/}" "$default_remote_ref" 2>/dev/null; then
      return 0
    fi
    if git -C "$repo_dir" checkout --detach "$default_remote_ref" 2>/dev/null; then
      return 0
    fi
  fi

  perror "Cannot checkout ref '$ref' in $repo_dir"
  return 1
}

