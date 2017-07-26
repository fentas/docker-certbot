#!/bin/bash
set -e
./letsencrypt.sh

if [ -n "${LE_CRON_TIME}" ]; then
  letsencrypt cron-auto-renewal
fi
