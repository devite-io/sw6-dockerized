#!/bin/bash

if [ $# -lt 2 ]; then
  echo "Usage: $0 <compose project path> <db password> [--no-bundles]"
  exit 1
fi


### BEGIN VALIDATION ###

composeProjectPath="$(realpath "$1")"
sqlPassword="$2"

cd "$composeProjectPath"

host="localhost"
port="3306"
user="root"

(docker compose exec database mariadb \
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
mkdir -p backups/$timestamp

# backup database
{
  (docker compose exec database mariadb-dump \
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
    --databases shopware \
  )
} > backups/$timestamp/shopware-db.sql

# backup Shopware
filesPath="backups/$timestamp/shopware-files"
containerPath="shopware:/usr/share/nginx/html"

mkdir -p $filesPath/public/bundles $filesPath/public/media $filesPath/public/thumbnail $filesPath/files/export
docker compose cp "$containerPath/public/bundles/." $filesPath/public/bundles/

if [ "$#" -eq 4 ] && [ "$2" == "--no-bundles" ]; then
  rm -rf $filesPath/public/bundles/administration
  rm -rf $filesPath/public/bundles/framework
  rm -rf $filesPath/public/bundles/installer
  rm -rf $filesPath/public/bundles/storefront
fi

docker compose cp "$containerPath/public/media/." $filesPath/public/media/
docker compose cp "$containerPath/public/thumbnail/." $filesPath/public/thumbnail/
docker compose cp "$containerPath/custom/." $filesPath/custom/ && rm -f $filesPath/custom/.htaccess
docker compose cp "$containerPath/files/." $filesPath/files/ && rm -rf $filesPath/files/.htaccess $filesPath/files/export
docker compose cp "$containerPath/var/." $filesPath/var/ && rm -rf $filesPath/var/log $filesPath/var/cache $filesPath/var/.htaccess $filesPath/var/theme*
docker compose cp "$containerPath/install.lock" $filesPath/
docker compose cp "$containerPath/composer.json" $filesPath/
docker compose cp "$containerPath/composer.lock" $filesPath/

# compress backup
tar -czf backups/$timestamp.tar.gz -C backups/$timestamp/ .
rm -r backups/$timestamp/