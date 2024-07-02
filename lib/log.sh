#!/usr/bin/env bash
# https://github.com/vtmx/logsh/blob/main/log

function log() {
  # Get status if exist
  [[ $2 ]] && {
    local status=$1
    shift
  }

  # Get message
  local msg="${1:-}"

  local pre="\e[37;1m--> "
  local post="\e[0m"
  # Add style in msg
  case $status in
  err*)
    msgo="$pre\e[31;1m[ERR]$post $msg"
    ;;
  suc*)
    msgo="$pre\e[32;1m[SUC]$post $msg"
    ;;
  war*)
    msgo="$pre\e[33;1m[WAR]$post $msg"
    ;;
  inf*)
    msgo="$pre\e[34;1m[INF]$post $msg"
    ;;
  *)
    msgo="$pre\e[30;1m[LOG]$post $msg"
    ;;
  esac

  # Show message in screen hightlight 'words'
  local out
  out="$(
    sed -E \
    -e "s/'(.[^']*)'/\\\e[36;1m'\\\e[32;1m\1\\\e[36;1m'\\\e[0m/g" \
    -e "s/\[1\[(.[^]]*)\]\]/\\\e[31m\1\\\e[0m/g" \
    -e "s/\[2\[(.[^]]*)\]\]/\\\e[32m\1\\\e[0m/g" \
    -e "s/\[3\[(.[^]]*)\]\]/\\\e[33m\1\\\e[0m/g" \
    -e "s/\[4\[(.[^]]*)\]\]/\\\e[34m\1\\\e[0m/g" \
    -e "s/\[5\[(.[^]]*)\]\]/\\\e[35m\1\\\e[0m/g" \
    -e "s/\[6\[(.[^]]*)\]\]/\\\e[36m\1\\\e[0m/g" \
    -e "s/\[7\[(.[^]]*)\]\]/\\\e[37m\1\\\e[0m/g" \
    <<<"$msgo"
  )"

  # printf -v right "| %-20.20s" "${BASH_SOURCE[1]}:${BASH_LINENO[1]}:${FUNCNAME[1]}"
  local filename
  filename=$(basename "${BASH_SOURCE[1]}")
  printf -v right "| %-1b |" "${filename}:${BASH_LINENO[1]}"
  printf "\r%*b\r%b   \b\b\b\n" "$(tput cols)" "$right" "$out";
}
