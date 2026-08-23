#!/bin/bash

if [ $# -ne 3 ]; then
  echo "Usage: $0 <compose project path> <db password> <backup path>"
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
  -e "CREATE DATABASE IF NOT EXISTS shopware;" \
) >/dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "Database authentication failed."
  exit 1
fi

backupFile="$3"

if [ ! -f "$backupFile" ]; then
  echo "Backup file '$backupFile' does not exist."
  exit 1
fi


### BEGIN RESTORE ###

mkdir backup-to-restore
tar -xzf "$backupFile" -C "backup-to-restore"

if [ $? -ne 0 ]; then
  echo "Failed to extract backup file."
  exit 1
fi

# restore Shopware
swDir="/usr/share/nginx/html"

docker compose exec shopware bash -c "cd $swDir/custom && rm -rf apps/*"
docker compose exec shopware bash -c "cd $swDir/public && rm -rf bundles/ media/ thumbnail/"
docker compose exec shopware bash -c "cd $swDir/files && rm -rf *"
docker compose exec shopware bash -c "cd $swDir/var && rm -rf */"

filesPath="backup-to-restore/shopware-files"
containerPath="shopware:$swDir"
docker compose cp "$filesPath/public/" $containerPath/
docker compose cp "$filesPath/custom/" $containerPath/
docker compose cp "$filesPath/files/" $containerPath/
docker compose cp "$filesPath/var/" $containerPath/
docker compose cp "$filesPath/install.lock" $containerPath/
docker compose cp "$filesPath/composer.json" $containerPath/
docker compose cp "$filesPath/composer.lock" $containerPath/

docker compose exec shopware bash -c "chown -R nginx:nginx $swDir && chmod -R 0777 $swDir"
docker compose exec --user nginx shopware bash -c "cd $swDir && composer install --no-dev"
docker compose exec --user nginx shopware bash -c "cd $swDir && bin/console es:reset --no-interaction"
docker compose exec --user nginx shopware bash -c "cd $swDir && bin/console es:admin:reset --no-interaction"
docker compose exec --user nginx shopware bash -c "cd $swDir && bin/console cache:clear:all"

# restore database
docker compose exec -T database mariadb \
  -h "$host" \
  -P "$port" \
  -u "$user" \
  -p"$sqlPassword" \
  shopware \
  < backup-to-restore/shopware-db.sql

docker compose restart shopware


### BEGIN CLEAN UP ###

rm -r backup-to-restore