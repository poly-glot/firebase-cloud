#!/bin/sh
set -e

echo "Pinging OCI MySQL at ${DB_HOST}..."

mysql \
  --host="${DB_HOST}" \
  --user="${DB_USER}" \
  --password="${DB_PASS}" \
  --ssl-mode=REQUIRED \
  --connect-timeout=10 \
  --execute="SELECT 1 AS ping;"

echo "MySQL ping successful."
