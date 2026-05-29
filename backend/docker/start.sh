#!/bin/sh
set -e

if [ -n "$AIVEN_CA_CERT" ]; then
  printf "%s" "$AIVEN_CA_CERT" > /tmp/aiven-ca.pem
  export MYSQL_ATTR_SSL_CA=/tmp/aiven-ca.pem
fi

php artisan optimize:clear

if [ "${RUN_MIGRATIONS:-true}" = "true" ]; then
  php artisan migrate --force
fi

if [ "${RUN_SEEDER:-true}" = "true" ]; then
  php artisan db:seed --force
fi

php artisan config:cache

exec php artisan serve --host=0.0.0.0 --port="${PORT:-8000}"
