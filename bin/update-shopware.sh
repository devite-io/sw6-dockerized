#!/bin/bash
cd "$(dirname "$0")"

if [ $# -ne 1 ]; then
  echo "Usage: $0 <shopware container>"
  exit 1
fi

swContainer="$1"
swDir="/usr/share/nginx/html"

# update symfony flex recipes
cd ./shopware-dockerized/sw-symfony-flex
git stash
composer recipes:update --no-interaction shopware/administration
composer recipes:update --no-interaction shopware/core
composer recipes:update --no-interaction shopware/storefront
git stash pop
cd ../../

# update Shopware
docker cp ./shopware-dockerized/sw-symfony-flex/composer.json shopware:/usr/share/nginx/html/
docker exec shopware bash -c "cd /usr/share/nginx/html && chmod 0777 composer.json && chown nginx:nginx composer.json"
docker exec --user nginx shopware bash -c "cd /usr/share/nginx/html && composer update --no-scripts"

# copy back updated composer files
docker cp shopware:/usr/share/nginx/html/composer.json ./shopware-dockerized/sw-symfony-flex/composer.json
docker cp shopware:/usr/share/nginx/html/composer.lock ./shopware-dockerized/sw-symfony-flex/composer.lock