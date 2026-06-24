#!/command/with-contenv /bin/bash
set -euo pipefail

# this seems redundant, if tzdata is installed. need to check this.
if [[ -n "${TZ:-}" ]] && [[ -f /usr/share/zoneinfo/"${TZ:-}" ]]; then
	ln -sf /usr/share/zoneinfo/"${TZ}" /etc/localtime
	echo "${TZ}" > /etc/timezone
	dpkg-reconfigure --frontend noninteractive tzdata
fi

mkdir -p /etc/openwebrx/openwebrx.conf.d /etc/openwebrx/vendor /var/lib/openwebrx /var/lib/openwebrx/vendor /tmp/openwebrx

echo "+++ adding new files (if any) to /etc/openwebrx"
cp -avn /owrx-init/etc/* /etc/openwebrx/
cp -a /owrx-init/etc/* /etc/openwebrx/vendor/

echo "+++ adding new files (if any) to /var/lib/openwebrx"
cp -avn /owrx-init/var/* /var/lib/openwebrx/
cp -a /owrx-init/var/* /var/lib/openwebrx/vendor/

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
  local sig="${1:-UNKNOWN}"
  echo "+++ run.sh received ${sig}; pid=$$ ppid=$PPID child=${child:-n/a}"

  if [[ -r "/proc/${PPID}/comm" ]]; then
    echo "+++ Parent process: $(cat "/proc/${PPID}/comm") (pid=${PPID})"
  fi
  if [[ -r "/proc/${PPID}/cmdline" ]]; then
    echo "+++ Parent cmdline: $(tr '\0' ' ' < "/proc/${PPID}/cmdline")"
  fi

  if [[ -r /proc/1/comm ]]; then
    echo "+++ PID 1 inside container: $(cat /proc/1/comm)"
  fi

  # Useful to correlate whether PID 1/supervisor asked us to stop.
  ps -o pid,ppid,stat,comm,args -p 1 -p $$ ${child:+-p "$child"} 2>/dev/null || true

  if command -v s6-svstat >/dev/null 2>&1 && [[ -d /run/service ]]; then
    echo "+++ s6 service states at signal time:"
    for svc in /run/service/*; do
      [[ -d "$svc" ]] || continue
      s6-svstat "$svc" 2>/dev/null || true
    done
  fi

  if [[ -n "${child:-}" ]]; then
    kill -TERM "$child" 2>/dev/null
  fi
}

trap '_term SIGTERM' SIGTERM
trap '_term SIGINT' SIGINT

log_termination_debug() {
  local status="$1"

  echo "+++ OpenWebRX+ terminated with exit status: ${status}"

  if (( status >= 128 )); then
    local sig=$((status - 128))
    # shellcheck disable=SC2155
    local sig_name="$(kill -l "${sig}" 2>/dev/null || true)"
    if [[ -n "${sig_name}" ]]; then
      echo "+++ Likely terminated by signal ${sig} (${sig_name})."
    else
      echo "+++ Likely terminated by signal ${sig}."
    fi
  fi

  if (( status == 137 || status == 143 )); then
    echo "+++ Hint: status ${status} often means SIGKILL/SIGTERM (OOM kill, docker stop, or external kill)."
  fi
}

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
set +e
wait "$child"
owrx_status=$?
set -e

log_termination_debug "$owrx_status"

echo "+++ List of processes after OWRX termination..."
ps xa
echo "+++ Exiting container."
exit "$owrx_status"
