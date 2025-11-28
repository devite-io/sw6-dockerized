#!/bin/bash

if [ $# -lt 3 ]; then
  echo "Usage: $0 <shopware container> <db container> <db password> [--no-bundles]"
  exit 1
fi


### BEGIN VALIDATION ###

swContainer="$1"
dbContainer="$2"
sqlPassword="$3"

host="localhost"
port="3306"
user="root"

(docker exec $dbContainer mariadb \
  -h "$host" \
  -P "$port" \
  -u "$user" \
  -p"$sqlPassword" \
  -e "SELECT 1;" \
) >/dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "Database authentication failed."
  exit 1
fi


### BEGIN BACKUP ###

timestamp="$(date '+%Y-%m-%d_%H-%M-%S')"
mkdir backup-$timestamp && cd backup-$timestamp

# backup database
{
  (docker exec $dbContainer mariadb-dump \
    -h "$host" \
    -P "$port" \
    -u "$user" \
    -p"$sqlPassword" \
    --add-drop-table \
    --ignore-table-data "shopware.customer_recovery" \
    --ignore-table-data "shopware.import_export_log" \
    --ignore-table-data "shopware.log_entry" \
    --ignore-table-data "shopware.notification" \
    --ignore-table-data "shopware.refresh_token" \
    --ignore-table-data "shopware.user_access_key" \
    --ignore-table-data "shopware.user_recovery" \
    --ignore-table-data "shopware.webhook_event_log" \
    --lock-all-tables \
    --hex-blob \
    --disable-comments \
    shopware \
  )
} > shopware-db.sql

# backup Shopware
mkdir shopware-files && cd shopware-files

containerPath="$swContainer:/usr/share/nginx/html"

mkdir -p public
docker cp -q "$containerPath/public/bundles/" public/bundles

if [ "$#" -eq 4 ] && [ "$2" == "--no-bundles" ]; then
  rm -rf public/bundles/administration
  rm -rf public/bundles/framework
  rm -rf public/bundles/installer
  rm -rf public/bundles/storefront
fi

docker cp -q "$containerPath/public/media/" public/media
docker cp -q "$containerPath/public/thumbnail/" public/thumbnail
docker cp -q "$containerPath/custom/" custom && rm -f custom/.htaccess
docker cp -q "$containerPath/files/" files && rm -rf files/.htaccess files/export
docker cp -q "$containerPath/var/" var && rm -rf var/log var/cache var/.htaccess var/theme*
docker cp -q "$containerPath/install.lock" ./
docker cp -q "$containerPath/composer.json" ./
docker cp -q "$containerPath/composer.lock" ./

cd ../

# compress backup
cd ../
tar -czf $timestamp.tar.gz backup-$timestamp/
rm -r backup-$timestamp/