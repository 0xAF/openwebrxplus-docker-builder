#!/command/with-contenv /bin/bash
set -euo pipefail

if [[ -n "${TZ}" ]]; then
	ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime
	dpkg-reconfigure --frontend noninteractive tzdata
fi

mkdir -p /etc/openwebrx/openwebrx.conf.d /var/lib/openwebrx /tmp/openwebrx

echo "+++ adding new files (if any) to /etc/openwebrx"
cp -avn /tmp/owrx-etc/* /etc/openwebrx/

echo "+++ adding new files (if any) to /var/lib/openwebrx"
cp -avn /tmp/owrx-var/* /var/lib/openwebrx/

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

create_socat_links() {
# Bind linked docker container to localhost socket using socat
  while read -r LOCAL PUBLIC; do
    if test -z "$LOCAL$PUBLIC"; then
      continue
    else
      SERV_FOLDER=/etc/s6-overlay/s6-rc.d/socat_${LOCAL}_${PUBLIC}
      #SERV_FOLDER=/run/service/socat_${LOCAL}_${PUBLIC}
      mkdir -p "${SERV_FOLDER}"
      CMD="socat -ls TCP4-LISTEN:${PUBLIC},fork,reuseaddr TCP4:127.0.0.1:${LOCAL}"
      # shellcheck disable=SC2039,SC3037
      echo -e "#!/bin/sh\nexec $CMD" > "${SERV_FOLDER}"/run
      chmod +x "${SERV_FOLDER}"/run
      echo "Forwarding port: ${PUBLIC} will be binded to localhost port ${LOCAL}" 1>&2
      s6-svlink /run/service "${SERV_FOLDER}"
    fi
  done << EOT
  $(env | sed -En 's|FORWARD_LOCALPORT_([0-9]+)=([0-9]+)|\1 \2|p')
EOT
}

create_socat_links

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
