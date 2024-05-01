#!/usr/bin/env bash
# https://github.com/vtmx/logsh/blob/main/log

function log() {
  # Get status if exist
  [[ $2 ]] && {
    local status=$1
    shift
  }

  # Get message
  local msg="${1^}"

  # Add style in msg
  case $status in
  err*)
    status=ERR
    msgo="$(echo [$(tput setaf 1)${status}$(tput sgr0)] $msg)"
    ;;
  suc*)
    status=SUC
    msgo="$(echo [$(tput setaf 2)${status}$(tput sgr0)] $msg)"
    ;;
  war*)
    status=WAR
    msgo="$(echo [$(tput setaf 3)${status}$(tput sgr0)] $msg)"
    ;;
  inf*)
    status=INF
    msgo="$(echo [$(tput setaf 4)${status}$(tput sgr0)] $msg)"
    ;;
  *)
    status=LOG
    msgo="[$status] $msg"
    ;;
  esac

  # Show message in screen hightlight 'words'
  sed -E "s/'(.[^']+)'/$(tput setaf 6)'$(tput setaf 2)\1$(tput setaf 6)'$(tput setaf sgr0)/g" <<<"$msgo"
}
