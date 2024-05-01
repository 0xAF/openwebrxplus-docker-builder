#!/bin/bash
set -euo pipefail

mkdir -p /etc/openwebrx/openwebrx.conf.d /var/lib/openwebrxA /tmp/openwebrx
if ! [ -f /etc/openwebrx/.remove-this-file-to-overwrite-folder-with-defaults ]; then
  echo;echo;echo;
  echo +++ overwriting /etc/openwebrx with defaults from package.
  echo;echo;echo
  cp -a /tmp/owrx-etc/* /etc/openwebrx/
  touch /etc/openwebrx/.remove-this-file-to-overwrite-folder-with-defaults
fi

if ! [ -f /var/lib/openwebrx/.remove-this-file-to-overwrite-folder-with-defaults ]; then
  echo;echo;echo;
  echo +++ overwriting /var/lib/openwebrx with defaults from package.
  echo;echo;echo
  cp -a /tmp/owrx-var/* /var/lib/openwebrx
  touch /var/lib/openwebrx/.remove-this-file-to-overwrite-folder-with-defaults
fi

if [[ ! -f /etc/openwebrx/openwebrx.conf.d/20-temporary-directory.conf ]] ; then
  cat << EOF > /etc/openwebrx/openwebrx.conf.d/20-temporary-directory.conf
[core]
temporary_directory = /tmp/openwebrx
EOF
fi
if [[ ! -z "${OPENWEBRX_ADMIN_USER:-}" ]] && [[ ! -z "${OPENWEBRX_ADMIN_PASSWORD:-}" ]] ; then
  if ! python3 openwebrx.py admin --silent hasuser "${OPENWEBRX_ADMIN_USER}" ; then
    OWRX_PASSWORD="${OPENWEBRX_ADMIN_PASSWORD}" python3 openwebrx.py admin --noninteractive adduser "${OPENWEBRX_ADMIN_USER}"
  fi
fi


_term() {
  echo "Caught signal!"
  kill -TERM "$child" 2>/dev/null
}

trap _term SIGTERM SIGINT

echo "Processes before start..."
ps xa

openwebrx $@ &

child=$!
wait "$child"
