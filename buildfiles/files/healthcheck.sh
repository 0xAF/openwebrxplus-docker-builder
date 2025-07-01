#!/bin/bash
ret=0

echo -n "Checking OWRX port (8073)..."
wget -T1 -q -O /dev/null http://localhost:8073/metrics
ret=$?
(( $ret > 0 )) && echo -n " not"
echo " ok"

echo -n "Checking for SDR devices..."
if [[ -n "$HEALTHCHECK_SDR_DEVICES" && "$HEALTHCHECK_SDR_DEVICES" -gt 0 ]]; then
  sdr_count=$(wget -T1 -q -O - http://localhost:8073/status.json | jq '[ .sdrs[].name ] | length')
  echo -n " found: $sdr_count..."
  if [[ "$sdr_count" -ne "$HEALTHCHECK_SDR_DEVICES" ]]; then
    echo -n " not"
    ret=1
  fi
else
  echo -n " (HEALTHCHECK_SDR_DEVICES not set or <= 0)"
fi
echo " ok"

while read -r VENDOR PRODUCT WANTED; do
  if test -z "$VENDOR$PRODUCT$WANTED"; then
    continue
  else
    echo -n "Looking for $WANTED USB device(s) with ID $VENDOR:$PRODUCT..."
    found=$(lsusb -d $VENDOR:$PRODUCT | wc -l)
    echo -n " found: $found..."
    if (( $found < $WANTED )); then
      echo -n " not"
      ret=1
    fi
    echo " ok"
  fi
done << EOT
$(env | sed -En 's|HEALTHCHECK_USB_([0-9a-fA-F]+)_([0-9a-fA-F]+)=([0-9]+)|\1 \2 \3|p')
EOT

(( $ret > 0 )) && exit 1
exit 0

