#!/usr/bin/env sh

set -o errexit
set -o xtrace

WWWUSER='www-data'

exec su -p -s /bin/sh -c "$@" -- "$WWWUSER"
