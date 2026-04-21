#!/bin/bash
set -e

# Fix permissions on directories used by FusionPBX and FreeSWITCH
for dir in /var/lib/freeswitch /usr/share/freeswitch /etc/freeswitch /var/log/freeswitch /var/www/fusionpbx /var/run/fusionpbx /var/cache/fusionpbx /etc/fusionpbx; do
    mkdir -p $dir
    chown -R www-data:www-data $dir || true
done

#Fix permissions to allow cache clearing
chmod 777 /var/cache/fusionpbx

# Start web stack
service postgresql start
service php8.2-fpm start

#Setup fusionpbx database if it doesn't exist
/usr/src/fusionpbx-install.sh/debian/resources/setup.sh

# Regenerate snakeoil certs if missing
if [ ! -f /etc/ssl/private/ssl-cert-snakeoil.key ]; then
    echo "Generating default SSL certificate..."
    make-ssl-cert generate-default-snakeoil --force-overwrite
fi

# Regenerate snakeoil certs if missing NGINX cert
if [ ! -f /etc/ssl/private/nginx.key ]; then
    echo "Copying default SSL certificate for NGINX..."
    cp -f /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/private/nginx.key
    cp -f /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/certs/nginx.crt
fi

service nginx start

# Start FreeSWITCH as root (or change to www-data if desired)
exec "$@"
