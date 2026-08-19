#!/bin/bash
scriptDir="$(realpath "$(dirname "$0")")"

if [ $# -ne 1 ]; then
  echo "Usage: $0 <compose project path>"
  exit 1
fi

composeProjectPath="$(realpath "$1")"
swDir="/usr/share/nginx/html"

# update composer dependencies
cd "$scriptDir/../shopware-dockerized/sw-symfony-flex"
composer update --no-scripts

# delete indices that might cause conflicts
cd "$composeProjectPath"
docker compose exec --user nginx shopware bash -c "cd $swDir && bin/console es:reset --no-interaction"
docker compose exec --user nginx shopware bash -c "cd $swDir && bin/console es:admin:reset --no-interaction"
docker compose exec --user nginx shopware bash -c "cd $swDir && bin/console cache:clear:all"

# update Shopware
docker compose cp "$scriptDir/../shopware-dockerized/sw-symfony-flex/composer.json" shopware:$swDir/
docker compose cp "$scriptDir/../shopware-dockerized/sw-symfony-flex/composer.lock" shopware:$swDir/
docker compose cp "$scriptDir/../shopware-dockerized/sw-symfony-flex/symfony.lock" shopware:$swDir/
docker compose exec shopware bash -c "cd $swDir && chmod 0777 composer.json composer.lock symfony.lock && chown nginx:nginx composer.json composer.lock symfony.lock"
docker compose exec --user nginx shopware bash -c "cd $swDir && composer update --no-scripts"

# copy back updated composer files
docker compose cp shopware:$swDir/composer.json "$scriptDir/../shopware-dockerized/sw-symfony-flex/composer.json"
docker compose cp shopware:$swDir/composer.lock "$scriptDir/../shopware-dockerized/sw-symfony-flex/composer.lock"
docker compose cp shopware:$swDir/symfony.lock "$scriptDir/../shopware-dockerized/sw-symfony-flex/symfony.lock"