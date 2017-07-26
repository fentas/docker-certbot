#!/bin/bash

: ${CERTBOT_DOMAINS:-"/certbot.domains"}
if [ -z "$(cat ${CERTBOT_DOMAINS})" ]; then
  echo "nothing to do"
  exit 0
fi

LE_CERT_ROOT="/etc/letsencrypt/live"
LE_LIST=$(letsencrypt list | awk 'NR > 1 {print}')
mkdir -p "${LE_CERT_ROOT}"

function .notInLeList { for needle in "${@}"; do
  if ! echo "${LE_LIST[@]}" | grep -q "${needle}"; then return 0; fi
done; return 1; }

while IFS= read -r -d '' line; do
  [ -z "${line}" ] || [ "${line:0:1}" == "#" ] && continue
  read -a domains <<<$line

  for domain in "${domains[@]}"; do
    status=$(curl -sw "%{http_code}" http://${domain}/.well-known/acme-challenge/ | grep -o '[[:digit:]]*$')
    [ "${status}" -ne 400 ] && {
      echo "error: expected http code 400 got ${status}"
      continue 2
    }
  done

  if [ ! -e "${LE_CERT_ROOT}/${domains[0]}" ]; then
    letsencrypt add "${domains[@]}"
    echo "debug: ${DOMAIN_FOLDER}"
  elif .notInLeList "${domains[@]}"; then
    # TODO maybe to cron [limit 20 req / 7 days => ~2 reqs / day]
    letsencrypt renew "${domains[@]}"
    echo "debug: renew"
  else
      echo "Cert up to date."
  fi
done <"${CERTBOT_DOMAINS}"
