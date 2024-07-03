#!/bin/bash
set -euo pipefail

mkdir -p /etc/openwebrx/openwebrx.conf.d /var/lib/openwebrx /tmp/openwebrx

echo "+++ adding new files (if any) to /etc/openwebrx"
cp -av --update=none /tmp/owrx-etc/* /etc/openwebrx/

echo "+++ adding new files (if any) to /var/lib/openwebrx"
cp -av --update=none /tmp/owrx-var/* /var/lib/openwebrx/

if [[ ! -f /etc/openwebrx/openwebrx.conf.d/20-temporary-directory.conf ]] ; then
  cat << EOF > /etc/openwebrx/openwebrx.conf.d/20-temporary-directory.conf
[core]
temporary_directory = /tmp/openwebrx
EOF
fi

if [[ -n "${OPENWEBRX_ADMIN_USER:-}" ]] && [[ -n "${OPENWEBRX_ADMIN_PASSWORD:-}" ]] ; then
  echo;echo;echo
  echo "+++ Adding admin user ${OPENWEBRX_ADMIN_USER:-}"
  if ! python3 openwebrx.py admin --silent hasuser "${OPENWEBRX_ADMIN_USER}" ; then
    OWRX_PASSWORD="${OPENWEBRX_ADMIN_PASSWORD}" python3 openwebrx.py admin --noninteractive adduser "${OPENWEBRX_ADMIN_USER}"
    echo "+++ Admin user ${OPENWEBRX_ADMIN_USER:-} added."
  else
    echo "+++ Admin user ${OPENWEBRX_ADMIN_USER:-} already exist."
  fi
fi


_term() {
  echo "Caught signal!"
  kill -TERM "$child" 2>/dev/null
}

trap _term SIGTERM SIGINT

echo "+++ List of processes before start..."
ps xa

echo "+++ OpenWebRX+ starting."
# shellcheck disable=SC2068
openwebrx $@ &

child=$!
wait "$child"
