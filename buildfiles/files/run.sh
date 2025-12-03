#!/command/with-contenv /bin/bash
set -euo pipefail

# this seems redundant, if tzdata is installed. need to check this.
if [[ -n "${TZ:-}" ]] && [[ -f /usr/share/zoneinfo/"${TZ:-}" ]]; then
	ln -sf /usr/share/zoneinfo/"${TZ}" /etc/localtime
	echo "${TZ}" > /etc/timezone
	dpkg-reconfigure --frontend noninteractive tzdata
fi

mkdir -p /etc/openwebrx/openwebrx.conf.d /var/lib/openwebrx /tmp/openwebrx

echo "+++ adding new files (if any) to /etc/openwebrx"
cp -avn /owrx-init/etc/* /etc/openwebrx/

echo "+++ adding new files (if any) to /var/lib/openwebrx"
cp -avn /owrx-init/var/* /var/lib/openwebrx/

if [[ ! -f /etc/openwebrx/openwebrx.conf.d/20-temporary-directory.conf ]] ; then
  cat << EOF > /etc/openwebrx/openwebrx.conf.d/20-temporary-directory.conf
[core]
temporary_directory = /tmp/openwebrx
EOF
fi

if [[ -n "${OPENWEBRX_ADMIN_USER:-}" ]] && [[ -n "${OPENWEBRX_ADMIN_PASSWORD:-}" ]] ; then
  echo;echo;echo
  echo "+++ Adding admin user ${OPENWEBRX_ADMIN_USER:-}"
  if ! openwebrx admin --silent hasuser "${OPENWEBRX_ADMIN_USER}" ; then
    OWRX_PASSWORD="${OPENWEBRX_ADMIN_PASSWORD}" openwebrx admin --noninteractive adduser "${OPENWEBRX_ADMIN_USER}"
    echo "+++ Admin user ${OPENWEBRX_ADMIN_USER:-} added."
  else
    echo "+++ Admin user ${OPENWEBRX_ADMIN_USER:-} already exist."
  fi
fi

#if [[ -n "${OPENWEBRX_ENABLE_SATDUMP:-}" ]]; then
#  echo;echo;echo
#  echo "+++ Enabling SATDump stuff..."
#  sed -i "/SatDump stuff is work in progress/ {
#    :a
#    n
#    /^[^#]/ b
#    s/^#//
#    ba
#  }" /usr/lib/python3/dist-packages/owrx/modes.py
#fi

create_socat_links() {
# Bind linked docker container to localhost socket using socat
  while read -r LOCAL PUBLIC; do
    if test -z "$LOCAL$PUBLIC"; then
      continue
    else
	  rm -rf /run/service/socat_${LOCAL}_${PUBLIC}
      SERV_FOLDER=/etc/s6-overlay/s6-rc.d/socat_${LOCAL}_${PUBLIC}
      #SERV_FOLDER=/run/service/socat_${LOCAL}_${PUBLIC}
      mkdir -p "${SERV_FOLDER}"
      CMD="socat -ls TCP4-LISTEN:${PUBLIC},fork,reuseaddr TCP4:127.0.0.1:${LOCAL}"
      # shellcheck disable=SC2039,SC3037
      echo -e "#!/bin/sh\nexec $CMD" > "${SERV_FOLDER}"/run
      chmod +x "${SERV_FOLDER}"/run
      echo -e "longrun" > "${SERV_FOLDER}"/type
      echo "+++ Forwarding port: ${PUBLIC} will be binded to localhost port ${LOCAL}" 1>&2
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

echo "+++ List of processes before OWRX start..."
ps xa

echo "+++ OpenWebRX+ starting."
openwebrx() {
  if [[ -f /openwebrx/openwebrx.py ]]; then
    cd /openwebrx
    # shellcheck disable=SC2068
    ./openwebrx.py $@
  else
    # shellcheck disable=SC2068
    command openwebrx $@
  fi
}
# shellcheck disable=SC2068
openwebrx $@ &

child=$!
wait "$child"
