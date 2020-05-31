#!/usr/bin/env sh

set -o errexit
set -o xtrace

WWWUSER='www-data'

if [ ! -e /volume/configuration/config.php ]; then
	cp ./config.php-dist /volume/configuration/config.php
fi

exec su -p -s /bin/sh -c "$@" -- "$WWWUSER"
