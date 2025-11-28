#!/bin/bash

if [ $# -ne 4 ]; then
  echo "Usage: $0 <shopware container> <db container> <db password> <backup path>"
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
  -e "CREATE DATABASE IF NOT EXISTS shopware;" \
) >/dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "Database authentication failed."
  exit 1
fi

backupFile="$4"

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

cd backup-to-restore/backup-*/

# restore Shopware
cd shopware-files

swDir="/usr/share/nginx/html"

docker exec $swContainer bash -c "cd $swDir/custom && rm -rf apps/*"
docker exec $swContainer bash -c "cd $swDir/public && rm -rf bundles/ media/ thumbnail/"
docker exec $swContainer bash -c "cd $swDir/files && rm -rf *"
docker exec $swContainer bash -c "cd $swDir/var && rm -rf */"

containerPath="$swContainer:$swDir"
docker cp -q "public/" $containerPath/
docker cp -q "custom/" $containerPath/
docker cp -q "files/" $containerPath/
docker cp -q "var/" $containerPath/
docker cp -q "install.lock" $containerPath/
docker cp -q "composer.json" $containerPath/
docker cp -q "composer.lock" $containerPath/

docker exec $swContainer bash -c "chown -R nginx:nginx $swDir"
docker exec --user nginx $swContainer bash -c "chmod -R 0777 $swDir"
docker exec --user nginx $swContainer bash -c "cd $swDir && composer install"
docker exec --user nginx $swContainer bash -c "cd $swDir && bin/console cache:clear --no-warmup"

cd ../

# restore database
(docker exec -i $dbContainer mariadb \
  -h "$host" \
  -P "$port" \
  -u "$user" \
  -p"$sqlPassword" \
  shopware \
) < shopware-db.sql

cd ../../
docker container restart $swContainer


### BEGIN CLEAN UP ###

rm -r backup-to-restore