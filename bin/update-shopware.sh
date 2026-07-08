#!/bin/bash
cd "$(dirname "$0")"

if [ $# -ne 1 ]; then
  echo "Usage: $0 <shopware container>"
  exit 1
fi

swContainer="$1"
swDir="/usr/share/nginx/html"

# update composer dependencies
cd ../shopware-dockerized/sw-symfony-flex
composer update --no-scripts
cd ../../

# delete indices that might cause conflicts
docker exec --user nginx $swContainer bash -c "cd $swDir && bin/console es:reset --no-interaction"
docker exec --user nginx $swContainer bash -c "cd $swDir && bin/console es:admin:reset --no-interaction"
docker exec --user nginx $swContainer bash -c "cd $swDir && bin/console cache:clear:all"

# update Shopware
docker cp ./shopware-dockerized/sw-symfony-flex/composer.json $swContainer:$swDir/
docker cp ./shopware-dockerized/sw-symfony-flex/composer.lock $swContainer:$swDir/
docker cp ./shopware-dockerized/sw-symfony-flex/symfony.lock $swContainer:$swDir/
docker exec $swContainer bash -c "cd $swDir && chmod 0777 composer.json composer.lock symfony.lock && chown nginx:nginx composer.json composer.lock symfony.lock"
docker exec --user nginx $swContainer bash -c "cd $swDir && composer update --no-scripts"

# copy back updated composer files
docker cp $swContainer:$swDir/composer.json ./shopware-dockerized/sw-symfony-flex/composer.json
docker cp $swContainer:$swDir/composer.lock ./shopware-dockerized/sw-symfony-flex/composer.lock
docker cp $swContainer:$swDir/symfony.lock ./shopware-dockerized/sw-symfony-flex/symfony.lock